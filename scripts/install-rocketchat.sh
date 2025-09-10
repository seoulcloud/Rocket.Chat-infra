#!/bin/bash

# Rocket.Chat 설치 스크립트
set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 변수 설정
MASTER_IP=""
SSH_KEY_PATH="~/.ssh/rocketchat-key.pem"
MONGODB_IP=""
REDIS_IP=""
CLOUDFRONT_DOMAIN=""
ROCKETCHAT_VERSION="latest"
ROCKETCHAT_REPLICAS=1

# 사용법 출력
usage() {
    echo "사용법: $0 -m <master_ip> -d <mongodb_ip> -r <redis_ip> -c <cloudfront_domain>"
    echo "예시: $0 -m 3.36.97.187 -d 10.0.3.100 -r 10.0.4.100 -c d1234567890.cloudfront.net"
    exit 1
}

# 인수 파싱
while getopts "m:d:r:c:" opt; do
    case $opt in
        m) MASTER_IP="$OPTARG" ;;
        d) MONGODB_IP="$OPTARG" ;;
        r) REDIS_IP="$OPTARG" ;;
        c) CLOUDFRONT_DOMAIN="$OPTARG" ;;
        *) usage ;;
    esac
done

# 필수 인수 확인
if [[ -z "$MASTER_IP" || -z "$MONGODB_IP" || -z "$REDIS_IP" || -z "$CLOUDFRONT_DOMAIN" ]]; then
    log_error "모든 필수 인수가 필요합니다."
    usage
fi

# SSH 키 파일 확인
if [[ ! -f "$SSH_KEY_PATH" ]]; then
    log_error "SSH 키 파일을 찾을 수 없습니다: $SSH_KEY_PATH"
    exit 1
fi

log_info "Rocket.Chat 설치를 시작합니다..."
log_info "Master IP: $MASTER_IP"
log_info "MongoDB IP: $MONGODB_IP"
log_info "Redis IP: $REDIS_IP"
log_info "CloudFront Domain: $CLOUDFRONT_DOMAIN"

# SSH 연결 테스트
test_ssh_connection() {
    log_info "SSH 연결 테스트: $MASTER_IP"
    
    if ! ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i "$SSH_KEY_PATH" ubuntu@"$MASTER_IP" 'echo "SSH connection successful"' >/dev/null 2>&1; then
        log_error "SSH 연결 실패: $MASTER_IP"
        exit 1
    fi
    log_info "SSH 연결 성공: $MASTER_IP"
}

# rocketchat 네임스페이스 생성
create_rocketchat_namespace() {
    log_info "rocketchat 네임스페이스 생성 중..."
    
    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" ubuntu@"$MASTER_IP" << 'EOF'
        kubectl create namespace rocketchat
        kubectl get namespaces
EOF
}

# Rocket.Chat ConfigMap 생성
create_rocketchat_configmap() {
    log_info "Rocket.Chat ConfigMap 생성 중..."
    
    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" ubuntu@"$MASTER_IP" << EOF
        cat > rocketchat-configmap.yaml << 'CONFIGMAP_EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: rocketchat-config
  namespace: rocketchat
data:
  MONGODB_URL: "mongodb://rocketchat:rocketchat123@${MONGODB_IP}:27017/rocketchat?replicaSet=rs0"
  REDIS_URL: "redis://:rocketchat123@${REDIS_IP}:6379"
  ROOT_URL: "https://${CLOUDFRONT_DOMAIN}"
  PORT: "3000"
CONFIGMAP_EOF

        kubectl apply -f rocketchat-configmap.yaml
EOF
}

# Rocket.Chat Deployment 생성
create_rocketchat_deployment() {
    log_info "Rocket.Chat Deployment 생성 중..."
    
    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" ubuntu@"$MASTER_IP" << EOF
        cat > rocketchat-deployment.yaml << 'DEPLOYMENT_EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rocketchat
  namespace: rocketchat
spec:
  replicas: ${ROCKETCHAT_REPLICAS}
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
        image: rocketchat/rocket.chat:${ROCKETCHAT_VERSION}
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
          valueFrom:
            configMapKeyRef:
              name: rocketchat-config
              key: ROOT_URL
        - name: PORT
          valueFrom:
            configMapKeyRef:
              name: rocketchat-config
              key: PORT
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /api/v1/info
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /api/v1/info
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
DEPLOYMENT_EOF

        kubectl apply -f rocketchat-deployment.yaml
EOF
}

# Rocket.Chat Service 생성
create_rocketchat_service() {
    log_info "Rocket.Chat Service 생성 중..."
    
    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" ubuntu@"$MASTER_IP" << 'EOF'
        cat > rocketchat-service.yaml << 'SERVICE_EOF'
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
SERVICE_EOF

        kubectl apply -f rocketchat-service.yaml
EOF
}

# Rocket.Chat HPA 생성
create_rocketchat_hpa() {
    log_info "Rocket.Chat HPA 생성 중..."
    
    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" ubuntu@"$MASTER_IP" << 'EOF'
        cat > rocketchat-hpa.yaml << 'HPA_EOF'
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: rocketchat-hpa
  namespace: rocketchat
spec:
  maxReplicas: 5
  minReplicas: 1
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: rocketchat
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
HPA_EOF

        kubectl apply -f rocketchat-hpa.yaml
EOF
}

# Rocket.Chat 상태 확인
check_rocketchat_status() {
    log_info "Rocket.Chat 상태 확인 중..."
    
    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" ubuntu@"$MASTER_IP" << 'EOF'
        echo "=== Rocket.Chat 네임스페이스 파드 상태 ==="
        kubectl get pods -n rocketchat
        
        echo -e "\n=== Rocket.Chat 서비스 상태 ==="
        kubectl get svc -n rocketchat
        
        echo -e "\n=== Rocket.Chat HPA 상태 ==="
        kubectl get hpa -n rocketchat
        
        echo -e "\n=== Rocket.Chat 서비스 포트 ==="
        kubectl get svc rocketchat-service -n rocketchat -o jsonpath='{.spec.ports[0].nodePort}'
        echo ""
EOF
}

# 메인 실행
main() {
    log_info "Rocket.Chat 설치를 시작합니다..."
    
    # SSH 연결 테스트
    test_ssh_connection
    
    # rocketchat 네임스페이스 생성
    create_rocketchat_namespace
    
    # Rocket.Chat ConfigMap 생성
    create_rocketchat_configmap
    
    # Rocket.Chat Deployment 생성
    create_rocketchat_deployment
    
    # Rocket.Chat Service 생성
    create_rocketchat_service
    
    # Rocket.Chat HPA 생성
    create_rocketchat_hpa
    
    # Rocket.Chat 상태 확인
    check_rocketchat_status
    
    log_info "Rocket.Chat 설치가 완료되었습니다!"
    log_info "Master 노드 접속: ssh -i $SSH_KEY_PATH ubuntu@$MASTER_IP"
    log_info "Rocket.Chat 접속: https://$CLOUDFRONT_DOMAIN"
    log_info "또는 직접 접속: http://$MASTER_IP:<NodePort>"
}

# 스크립트 실행
main "$@"
