#!/bin/bash

# Prometheus & Grafana 설치 스크립트
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
PROMETHEUS_VERSION="v2.45.0"
GRAFANA_VERSION="10.0.0"
GRAFANA_ADMIN_PASSWORD="admin123"

# 사용법 출력
usage() {
    echo "사용법: $0 -m <master_ip>"
    echo "예시: $0 -m 3.36.97.187"
    exit 1
}

# 인수 파싱
while getopts "m:" opt; do
    case $opt in
        m) MASTER_IP="$OPTARG" ;;
        *) usage ;;
    esac
done

# 필수 인수 확인
if [[ -z "$MASTER_IP" ]]; then
    log_error "Master IP가 필요합니다."
    usage
fi

# SSH 키 파일 확인
if [[ ! -f "$SSH_KEY_PATH" ]]; then
    log_error "SSH 키 파일을 찾을 수 없습니다: $SSH_KEY_PATH"
    exit 1
fi

log_info "Prometheus & Grafana 설치를 시작합니다..."
log_info "Master IP: $MASTER_IP"

# SSH 연결 테스트
test_ssh_connection() {
    log_info "SSH 연결 테스트: $MASTER_IP"
    
    if ! ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i "$SSH_KEY_PATH" ubuntu@"$MASTER_IP" 'echo "SSH connection successful"' >/dev/null 2>&1; then
        log_error "SSH 연결 실패: $MASTER_IP"
        exit 1
    fi
    log_info "SSH 연결 성공: $MASTER_IP"
}

# monitoring 네임스페이스 생성
create_monitoring_namespace() {
    log_info "monitoring 네임스페이스 생성 중..."
    
    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" ubuntu@"$MASTER_IP" << 'EOF'
        kubectl create namespace monitoring
        kubectl get namespaces
EOF
}

# Prometheus 설치
install_prometheus() {
    log_info "Prometheus 설치 중..."
    
    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" ubuntu@"$MASTER_IP" << EOF
        # Prometheus ConfigMap 생성
        cat > prometheus-config.yaml << 'PROMETHEUS_EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      evaluation_interval: 15s
    
    rule_files:
      # - "first_rules.yml"
      # - "second_rules.yml"
    
    scrape_configs:
      - job_name: 'prometheus'
        static_configs:
          - targets: ['localhost:9090']
      
      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
          - role: pod
            namespaces:
              names:
                - rocketchat
        relabel_configs:
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
            action: keep
            regex: true
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
            action: replace
            target_label: __metrics_path__
            regex: (.+)
          - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
            action: replace
            regex: ([^:]+)(?::\d+)?;(\\d+)
            replacement: \$1:\$2
            target_label: __address__
          - action: labelmap
            regex: __meta_kubernetes_pod_label_(.+)
          - source_labels: [__meta_kubernetes_namespace]
            action: replace
            target_label: kubernetes_namespace
          - source_labels: [__meta_kubernetes_pod_name]
            action: replace
            target_label: kubernetes_pod_name
      
      - job_name: 'kubernetes-nodes'
        kubernetes_sd_configs:
          - role: node
        relabel_configs:
          - action: labelmap
            regex: __meta_kubernetes_node_label_(.+)
          - target_label: __address__
            replacement: kubernetes.default.svc:443
          - source_labels: [__meta_kubernetes_node_name]
            regex: (.+)
            target_label: __metrics_path__
            replacement: /api/v1/nodes/\${1}/proxy/metrics
PROMETHEUS_EOF

        kubectl apply -f prometheus-config.yaml
        
        # Prometheus PersistentVolumeClaim 생성
        cat > prometheus-pvc.yaml << 'PVC_EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: prometheus-pvc
  namespace: monitoring
spec:
  access_modes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
PVC_EOF

        kubectl apply -f prometheus-pvc.yaml
        
        # Prometheus Deployment 생성
        cat > prometheus-deployment.yaml << 'DEPLOYMENT_EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
      - name: prometheus
        image: prom/prometheus:${PROMETHEUS_VERSION}
        ports:
        - containerPort: 9090
        volumeMounts:
        - name: prometheus-config
          mountPath: /etc/prometheus
        - name: prometheus-storage
          mountPath: /prometheus
        args:
          - '--config.file=/etc/prometheus/prometheus.yml'
          - '--storage.tsdb.path=/prometheus'
          - '--web.console.libraries=/etc/prometheus/console_libraries'
          - '--web.console.templates=/etc/prometheus/consoles'
          - '--storage.tsdb.retention.time=200h'
          - '--web.enable-lifecycle'
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
      volumes:
      - name: prometheus-config
        configMap:
          name: prometheus-config
      - name: prometheus-storage
        persistentVolumeClaim:
          claimName: prometheus-pvc
DEPLOYMENT_EOF

        kubectl apply -f prometheus-deployment.yaml
        
        # Prometheus Service 생성
        cat > prometheus-service.yaml << 'SERVICE_EOF'
apiVersion: v1
kind: Service
metadata:
  name: prometheus-service
  namespace: monitoring
spec:
  selector:
    app: prometheus
  ports:
  - port: 9090
    targetPort: 9090
  type: NodePort
SERVICE_EOF

        kubectl apply -f prometheus-service.yaml
EOF
    
    if [[ $? -eq 0 ]]; then
        log_info "Prometheus 설치 완료"
    else
        log_error "Prometheus 설치 실패"
        exit 1
    fi
}

# Grafana 설치
install_grafana() {
    log_info "Grafana 설치 중..."
    
    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" ubuntu@"$MASTER_IP" << EOF
        # Grafana ConfigMap 생성
        cat > grafana-config.yaml << 'GRAFANA_EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-config
  namespace: monitoring
data:
  grafana.ini: |
    [server]
    root_url = http://localhost:3000/
    
    [security]
    admin_user = admin
    admin_password = ${GRAFANA_ADMIN_PASSWORD}
    
    [users]
    allow_sign_up = false
    auto_assign_org = true
    auto_assign_org_role = Viewer
    
    [auth.anonymous]
    enabled = true
    org_name = Main Org.
    org_role = Viewer
GRAFANA_EOF

        kubectl apply -f grafana-config.yaml
        
        # Grafana PersistentVolumeClaim 생성
        cat > grafana-pvc.yaml << 'PVC_EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: grafana-pvc
  namespace: monitoring
spec:
  access_modes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
PVC_EOF

        kubectl apply -f grafana-pvc.yaml
        
        # Grafana Deployment 생성
        cat > grafana-deployment.yaml << 'DEPLOYMENT_EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:${GRAFANA_VERSION}
        ports:
        - containerPort: 3000
        volumeMounts:
        - name: grafana-config
          mountPath: /etc/grafana/grafana.ini
          subPath: grafana.ini
        - name: grafana-storage
          mountPath: /var/lib/grafana
        env:
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: "${GRAFANA_ADMIN_PASSWORD}"
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "200m"
      volumes:
      - name: grafana-config
        configMap:
          name: grafana-config
      - name: grafana-storage
        persistentVolumeClaim:
          claimName: grafana-pvc
DEPLOYMENT_EOF

        kubectl apply -f grafana-deployment.yaml
        
        # Grafana Service 생성
        cat > grafana-service.yaml << 'SERVICE_EOF'
apiVersion: v1
kind: Service
metadata:
  name: grafana-service
  namespace: monitoring
spec:
  selector:
    app: grafana
  ports:
  - port: 3000
    targetPort: 3000
  type: NodePort
SERVICE_EOF

        kubectl apply -f grafana-service.yaml
EOF
    
    if [[ $? -eq 0 ]]; then
        log_info "Grafana 설치 완료"
    else
        log_error "Grafana 설치 실패"
        exit 1
    fi
}

# 모니터링 상태 확인
check_monitoring_status() {
    log_info "모니터링 상태 확인 중..."
    
    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" ubuntu@"$MASTER_IP" << 'EOF'
        echo "=== 모니터링 네임스페이스 파드 상태 ==="
        kubectl get pods -n monitoring
        
        echo -e "\n=== 모니터링 서비스 상태 ==="
        kubectl get svc -n monitoring
        
        echo -e "\n=== Prometheus 서비스 포트 ==="
        kubectl get svc prometheus-service -n monitoring -o jsonpath='{.spec.ports[0].nodePort}'
        echo ""
        
        echo -e "\n=== Grafana 서비스 포트 ==="
        kubectl get svc grafana-service -n monitoring -o jsonpath='{.spec.ports[0].nodePort}'
        echo ""
EOF
}

# 메인 실행
main() {
    log_info "Prometheus & Grafana 설치를 시작합니다..."
    
    # SSH 연결 테스트
    test_ssh_connection
    
    # monitoring 네임스페이스 생성
    create_monitoring_namespace
    
    # Prometheus 설치
    install_prometheus
    
    # Grafana 설치
    install_grafana
    
    # 모니터링 상태 확인
    check_monitoring_status
    
    log_info "Prometheus & Grafana 설치가 완료되었습니다!"
    log_info "Master 노드 접속: ssh -i $SSH_KEY_PATH ubuntu@$MASTER_IP"
    log_info "Prometheus 접속: http://$MASTER_IP:<NodePort>"
    log_info "Grafana 접속: http://$MASTER_IP:<NodePort> (admin/${GRAFANA_ADMIN_PASSWORD})"
}

# 스크립트 실행
main "$@"
