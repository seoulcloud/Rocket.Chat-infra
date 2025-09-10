#!/bin/bash

# k3s 클러스터 설치 스크립트
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
WORKER_IPS=()
SSH_KEY_PATH="~/.ssh/rocketchat-key.pem"

# 사용법 출력
usage() {
    echo "사용법: $0 -m <master_ip> -w <worker_ip1,worker_ip2>"
    echo "예시: $0 -m 3.36.97.187 -w 3.36.97.188,3.36.97.189"
    exit 1
}

# 인수 파싱
while getopts "m:w:" opt; do
    case $opt in
        m) MASTER_IP="$OPTARG" ;;
        w) IFS=',' read -ra WORKER_IPS <<< "$OPTARG" ;;
        *) usage ;;
    esac
done

# 필수 인수 확인
if [[ -z "$MASTER_IP" || ${#WORKER_IPS[@]} -eq 0 ]]; then
    log_error "Master IP와 Worker IP가 필요합니다."
    usage
fi

# SSH 키 파일 확인
if [[ ! -f "$SSH_KEY_PATH" ]]; then
    log_error "SSH 키 파일을 찾을 수 없습니다: $SSH_KEY_PATH"
    exit 1
fi

log_info "k3s 클러스터 설치를 시작합니다..."
log_info "Master IP: $MASTER_IP"
log_info "Worker IPs: ${WORKER_IPS[*]}"

# SSH 연결 테스트
test_ssh_connection() {
    local ip=$1
    log_info "SSH 연결 테스트: $ip"
    
    if ! ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i "$SSH_KEY_PATH" ubuntu@"$ip" 'echo "SSH connection successful"' >/dev/null 2>&1; then
        log_error "SSH 연결 실패: $ip"
        return 1
    fi
    log_info "SSH 연결 성공: $ip"
    return 0
}

# k3s Master 설치
install_k3s_master() {
    log_info "k3s Master 설치 중..."
    
    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" ubuntu@"$MASTER_IP" << 'EOF'
        # 시스템 업데이트
        sudo apt-get update -y
        sudo apt-get upgrade -y
        
        # k3s 설치
        curl -sfL https://get.k3s.io | sh -s - server \
            --write-kubeconfig-mode 644 \
            --disable traefik \
            --disable servicelb
        
        # kubectl 설치
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
        
        # Helm 설치
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
        
        # kubeconfig 설정
        mkdir -p /home/ubuntu/.kube
        sudo cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
        sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config
        
        # k3s 서비스 상태 확인
        sudo systemctl status k3s --no-pager
EOF
    
    if [[ $? -eq 0 ]]; then
        log_info "k3s Master 설치 완료"
    else
        log_error "k3s Master 설치 실패"
        exit 1
    fi
}

# k3s Worker 설치
install_k3s_worker() {
    local worker_ip=$1
    log_info "k3s Worker 설치 중: $worker_ip"
    
    # Master에서 토큰 가져오기
    local token=$(ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" ubuntu@"$MASTER_IP" 'sudo cat /var/lib/rancher/k3s/server/node-token')
    
    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" ubuntu@"$worker_ip" << EOF
        # 시스템 업데이트
        sudo apt-get update -y
        sudo apt-get upgrade -y
        
        # k3s Worker 설치
        curl -sfL https://get.k3s.io | K3S_URL=https://$MASTER_IP:6443 K3S_TOKEN=$token sh -
        
        # kubectl 설치
        curl -LO "https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
        
        # k3s 서비스 상태 확인
        sudo systemctl status k3s-agent --no-pager
EOF
    
    if [[ $? -eq 0 ]]; then
        log_info "k3s Worker 설치 완료: $worker_ip"
    else
        log_error "k3s Worker 설치 실패: $worker_ip"
        exit 1
    fi
}

# 클러스터 상태 확인
check_cluster_status() {
    log_info "클러스터 상태 확인 중..."
    
    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" ubuntu@"$MASTER_IP" << 'EOF'
        echo "=== 노드 상태 ==="
        kubectl get nodes
        
        echo -e "\n=== 파드 상태 ==="
        kubectl get pods --all-namespaces
        
        echo -e "\n=== 서비스 상태 ==="
        kubectl get svc --all-namespaces
EOF
}

# 메인 실행
main() {
    log_info "k3s 클러스터 설치를 시작합니다..."
    
    # SSH 연결 테스트
    test_ssh_connection "$MASTER_IP"
    for worker_ip in "${WORKER_IPS[@]}"; do
        test_ssh_connection "$worker_ip"
    done
    
    # k3s Master 설치
    install_k3s_master
    
    # k3s Worker 설치
    for worker_ip in "${WORKER_IPS[@]}"; do
        install_k3s_worker "$worker_ip"
    done
    
    # 클러스터 상태 확인
    check_cluster_status
    
    log_info "k3s 클러스터 설치가 완료되었습니다!"
    log_info "Master 노드 접속: ssh -i $SSH_KEY_PATH ubuntu@$MASTER_IP"
}

# 스크립트 실행
main "$@"
