#!/bin/bash

# k3s 설치를 위한 공통 User Data 스크립트
set -e

# 시스템 업데이트
apt-get update
apt-get upgrade -y

# 필요한 패키지 설치
apt-get install -y curl wget git

# Docker 설치 (k3s가 필요로 함)
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu

# k3s 설치
curl -sfL https://get.k3s.io | sh -

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

# 로그 정리
echo "k3s installation completed" > /var/log/k3s-setup.log
