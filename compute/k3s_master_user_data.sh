#!/bin/bash

# k3s Master Node 설치 및 설정 스크립트
set -e

# 시스템 업데이트
apt-get update
apt-get upgrade -y

# k3s 설치
curl -sfL https://get.k3s.io | sh -s - server \
  --write-kubeconfig-mode 644 \
  --disable traefik \
  --disable servicelb

# kubectl 설치
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Helm 설치
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# kubeconfig 설정
mkdir -p /home/ubuntu/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube

# Rocket.Chat용 네임스페이스 생성
kubectl create namespace rocketchat

# MongoDB 및 Redis 연결 정보를 위한 ConfigMap 생성
kubectl create configmap rocketchat-config \
  --from-literal=MONGODB_URL="mongodb://rocketchat:rocketchat123@${mongodb_ip}:27017/rocketchat?replicaSet=rs0" \
  --from-literal=REDIS_URL="redis://:rocketchat123@${redis_ip}:6379" \
  --namespace=rocketchat

# Rocket.Chat 배포를 위한 YAML 파일 생성
cat > /home/ubuntu/rocketchat-deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rocketchat
  namespace: rocketchat
spec:
  replicas: 1
  selector:
    matchLabels:
      app: rocketchat
  template:
    metadata:
      labels:
        app: rocketchat
    spec:
      containers:
      - name: rocketchat
        image: rocketchat/rocket.chat:latest
        ports:
        - containerPort: 3000
        env:
        - name: MONGO_URL
          valueFrom:
            configMapKeyRef:
              name: rocketchat-config
              key: MONGODB_URL
        - name: REDIS_URL
          valueFrom:
            configMapKeyRef:
              name: rocketchat-config
              key: REDIS_URL
        - name: ROOT_URL
          value: "http://localhost:3000"
        - name: PORT
          value: "3000"
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: rocketchat-service
  namespace: rocketchat
spec:
  selector:
    app: rocketchat
  ports:
  - port: 3000
    targetPort: 3000
  type: NodePort
EOF

# Rocket.Chat 배포
kubectl apply -f /home/ubuntu/rocketchat-deployment.yaml

# 로그 정리
echo "k3s master installation and Rocket.Chat deployment completed" > /var/log/k3s-setup.log