# 🚀 Rocket.Chat 배포 및 테스트 가이드

## 📋 사전 준비사항

### 1. AWS 계정 설정
```bash
# AWS CLI 설정
aws configure
# AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, Default region 입력
```

### 2. EC2 Key Pair (자동 생성)
```bash
# Key Pair는 Terraform이 자동으로 생성하고 keys/ 폴더에 저장합니다
# 수동 생성 불필요
```

### 3. Terraform 설정
```bash
# terraform.tfvars 파일 생성
cp terraform.tfvars.example terraform.tfvars
# 필요시 변수 값 수정 (Key Pair는 자동 생성됨)
```

## 🏗️ 인프라 배포

### 1. Terraform 초기화 및 배포
```bash
# Terraform 초기화
terraform init

# 배포 계획 확인
terraform plan

# 인프라 배포 (약 10-15분 소요)
terraform apply
```

### 2. 배포 완료 후 출력 정보 확인
```bash
# 배포 결과 출력
terraform output

# 주요 정보 저장
export ALB_DNS=$(terraform output -raw alb_dns_name)
export K3S_MASTER_IP=$(terraform output -raw k3s_master_public_ip)
export ROCKETCHAT_URL=$(terraform output -raw rocketchat_access_url)
```

## 🔧 k3s 클러스터 설정

### 1. k3s Master 노드 접속
```bash
# k3s Master 노드 SSH 접속
ssh -i keys/rocketchat-key.pem ubuntu@$K3S_MASTER_IP

# k3s 클러스터 상태 확인
sudo kubectl get nodes
sudo kubectl get pods --all-namespaces
```

### 2. k3s Worker 노드 토큰 설정
```bash
# Master 노드에서 토큰 확인
sudo cat /var/lib/rancher/k3s/server/node-token

# Worker 노드들에 접속하여 토큰 설정
# (User Data에서 자동으로 설정되지만 수동 확인 가능)
```

## 📱 Rocket.Chat 애플리케이션 배포

### 1. Rocket.Chat 배포 확인
```bash
# k3s Master 노드에서 실행
sudo kubectl get pods -n rocketchat
sudo kubectl get svc -n rocketchat

# Rocket.Chat 파드 로그 확인
sudo kubectl logs -f deployment/rocketchat -n rocketchat
```

### 2. Rocket.Chat 접속 테스트
```bash
# ALB를 통한 접속 테스트
curl -I http://$ALB_DNS

# 브라우저에서 접속
echo "Rocket.Chat URL: http://$ALB_DNS"
```

## 📊 모니터링 설정

### 1. Prometheus 배포 확인
```bash
# Prometheus 파드 상태 확인
sudo kubectl get pods -n monitoring
sudo kubectl get svc -n monitoring

# Prometheus 접속 (NodePort 30001)
echo "Prometheus URL: http://$K3S_MASTER_IP:30001"
```

### 2. Grafana 배포 확인
```bash
# Grafana 파드 상태 확인
sudo kubectl get pods -n monitoring
sudo kubectl get svc -n monitoring

# Grafana 접속 (NodePort 30000)
echo "Grafana URL: http://$K3S_MASTER_IP:30000"
echo "Grafana 계정: admin / admin123"
```

## 🧪 k6 부하 테스트

### 1. k6 설치
```bash
# k6 설치 (로컬 머신 또는 테스트 서버)
# Ubuntu/Debian
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6

# macOS
brew install k6

# Windows
choco install k6
```

### 2. k6 테스트 스크립트 생성
```javascript
// rocketchat-load-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '2m', target: 10 }, // 2분간 10명까지 증가
    { duration: '5m', target: 10 }, // 5분간 10명 유지
    { duration: '2m', target: 20 }, // 2분간 20명까지 증가
    { duration: '5m', target: 20 }, // 5분간 20명 유지
    { duration: '2m', target: 0 },  // 2분간 0명까지 감소
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000'], // 95% 요청이 2초 이내
    http_req_failed: ['rate<0.1'],     // 실패율 10% 미만
  },
};

const BASE_URL = 'http://YOUR_ALB_DNS'; // ALB DNS로 변경

export default function () {
  // 메인 페이지 접속
  let response = http.get(`${BASE_URL}`);
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 2000ms': (r) => r.timings.duration < 2000,
  });

  // API 엔드포인트 테스트
  response = http.get(`${BASE_URL}/api/v1/info`);
  check(response, {
    'API status is 200': (r) => r.status === 200,
  });

  sleep(1);
}
```

### 3. k6 테스트 실행
```bash
# 기본 부하 테스트
k6 run rocketchat-load-test.js

# 상세 결과와 함께 실행
k6 run --out json=results.json rocketchat-load-test.js

# 실시간 모니터링과 함께 실행
k6 run --out influxdb=http://localhost:8086/k6 rocketchat-load-test.js
```

## 📈 성능 모니터링

### 1. Grafana 대시보드 설정
```bash
# Grafana 접속 후 Prometheus 데이터소스 추가
# URL: http://prometheus-service:9090
# Access: Server (default)
```

### 2. 주요 메트릭 확인
- **CPU 사용률**: `rate(container_cpu_usage_seconds_total[5m])`
- **메모리 사용률**: `container_memory_usage_bytes`
- **네트워크 트래픽**: `rate(container_network_receive_bytes_total[5m])`
- **HTTP 요청 수**: `rate(http_requests_total[5m])`

## 🔄 HPA 테스트

### 1. HPA 상태 확인
```bash
# HPA 상태 확인
sudo kubectl get hpa -n rocketchat

# HPA 상세 정보
sudo kubectl describe hpa rocketchat-hpa -n rocketchat
```

### 2. 부하 증가 테스트
```bash
# k6로 높은 부하 생성
k6 run --vus 50 --duration 10m rocketchat-load-test.js

# HPA 동작 확인
watch kubectl get hpa -n rocketchat
```

## 🧹 정리 작업

### 1. 인프라 삭제
```bash
# 모든 리소스 삭제
terraform destroy

# 확인 후 yes 입력
```

### 2. 로컬 파일 정리
```bash
# 생성된 파일들 정리
rm -f results.json
rm -f rocketchat-load-test.js
```

## 🚨 문제 해결

### 1. Rocket.Chat 접속 불가
```bash
# 파드 상태 확인
sudo kubectl get pods -n rocketchat
sudo kubectl describe pod <pod-name> -n rocketchat

# 서비스 상태 확인
sudo kubectl get svc -n rocketchat
sudo kubectl describe svc rocketchat-service -n rocketchat
```

### 2. 데이터베이스 연결 오류
```bash
# MongoDB 연결 테스트
sudo kubectl exec -it <rocketchat-pod> -n rocketchat -- mongo --host <mongodb-ip>:27017

# Redis 연결 테스트
sudo kubectl exec -it <rocketchat-pod> -n rocketchat -- redis-cli -h <redis-ip> -p 6379 -a rocketchat123 ping
```

### 3. k3s 클러스터 문제
```bash
# 클러스터 상태 확인
sudo kubectl get nodes
sudo kubectl get pods --all-namespaces

# k3s 서비스 재시작
sudo systemctl restart k3s
```

## 📞 지원

문제가 발생하면 다음을 확인하세요:
1. AWS 콘솔에서 리소스 상태 확인
2. CloudWatch 로그 확인
3. k3s 클러스터 로그 확인
4. 보안 그룹 설정 확인
