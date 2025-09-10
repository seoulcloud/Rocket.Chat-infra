# 🚀 Rocket.Chat 인프라 설치 매뉴얼

## 📋 개요

이 매뉴얼은 Terraform으로 생성된 AWS 인프라에 k3s, Prometheus, Grafana, Rocket.Chat을 설치하는 방법을 설명합니다.

## 🏗️ 인프라 구성

### AWS 리소스
- **VPC**: 10.0.0.0/16
- **Public Subnets**: 10.0.1.0/24, 10.0.2.0/24
- **Private Subnets**: 10.0.3.0/24, 10.0.4.0/24
- **EC2 Instances**: k3s Master, k3s Workers, MongoDB, Redis
- **Security Groups**: 필요한 포트만 개방
- **IAM Roles**: k3s 및 애플리케이션용 서비스 계정
- **S3 Buckets**: 파일 저장, 로그, 백업용
- **CloudFront**: CDN 및 SSL 종료

### k3s 클러스터
- **Master Node**: 1개 (k3s 서버)
- **Worker Nodes**: 2개 (k3s 에이전트)
- **네트워크**: Flannel CNI
- **스토리지**: 로컬 스토리지

## 📦 사전 준비사항

### 1. Terraform 인프라 배포
```bash
# Terraform 초기화
terraform init

# 배포 계획 확인
terraform plan

# 인프라 배포
terraform apply
```

### 2. 필요한 정보 수집
```bash
# Terraform 출력 정보 확인
terraform output

# 주요 정보 저장
export MASTER_IP=$(terraform output -raw k3s_master_public_ip)
export WORKER_IPS=$(terraform output -raw k3s_worker_public_ips)
export MONGODB_IP=$(terraform output -raw mongodb_private_ip)
export REDIS_IP=$(terraform output -raw redis_private_ip)
export CLOUDFRONT_DOMAIN=$(terraform output -raw cloudfront_domain_name)
```

### 3. SSH 키 페어 생성 및 다운로드
```bash
# AWS 콘솔에서 키 페어 생성:
# 1. EC2 콘솔 → Key Pairs → Create key pair
# 2. 이름: rocketchat-key
# 3. 키 페어 유형: RSA
# 4. 프라이빗 키 파일 형식: .pem
# 5. Create key pair 클릭하여 다운로드

# 다운로드한 키 파일을 ~/.ssh/ 폴더로 이동
mv ~/Downloads/rocketchat-key.pem ~/.ssh/

# SSH 키 권한 설정
chmod 400 ~/.ssh/rocketchat-key.pem
```

## 🔧 설치 단계

### 1단계: k3s 클러스터 설치

```bash
# k3s 설치 스크립트 실행
./scripts/install-k3s.sh -m $MASTER_IP -w $WORKER_IPS

# 예시
./scripts/install-k3s.sh -m 3.36.97.187 -w 3.36.97.188,3.36.97.189
```

**설치 내용:**
- k3s Master 노드에 k3s 서버 설치
- k3s Worker 노드들에 k3s 에이전트 설치
- kubectl 및 Helm 설치
- 클러스터 상태 확인

**확인 방법:**
```bash
# Master 노드 접속
ssh -i ~/.ssh/rocketchat-key.pem ubuntu@$MASTER_IP

# 클러스터 상태 확인
kubectl get nodes
kubectl get pods --all-namespaces
```

### 2단계: 모니터링 시스템 설치 (Prometheus & Grafana)

```bash
# 모니터링 설치 스크립트 실행
./scripts/install-monitoring.sh -m $MASTER_IP

# 예시
./scripts/install-monitoring.sh -m 3.36.97.187
```

**설치 내용:**
- monitoring 네임스페이스 생성
- Prometheus 설치 (메트릭 수집)
- Grafana 설치 (대시보드)
- PersistentVolumeClaim 생성

**접속 방법:**
```bash
# Prometheus 접속
http://$MASTER_IP:<Prometheus_NodePort>

# Grafana 접속
http://$MASTER_IP:<Grafana_NodePort>
# 로그인: admin / admin123
```

### 3단계: Rocket.Chat 설치

```bash
# Rocket.Chat 설치 스크립트 실행
./scripts/install-rocketchat.sh -m $MASTER_IP -d $MONGODB_IP -r $REDIS_IP -c $CLOUDFRONT_DOMAIN

# 예시
./scripts/install-rocketchat.sh -m 3.36.97.187 -d 10.0.3.100 -r 10.0.4.100 -c d1234567890.cloudfront.net
```

**설치 내용:**
- rocketchat 네임스페이스 생성
- Rocket.Chat ConfigMap 생성
- Rocket.Chat Deployment 생성
- Rocket.Chat Service 생성
- HorizontalPodAutoscaler 생성

**접속 방법:**
```bash
# CloudFront를 통한 접속 (권장)
https://$CLOUDFRONT_DOMAIN

# 직접 접속
http://$MASTER_IP:<RocketChat_NodePort>
```

## 🔍 상태 확인

### 클러스터 전체 상태
```bash
# Master 노드 접속
ssh -i ~/.ssh/rocketchat-key.pem ubuntu@$MASTER_IP

# 모든 네임스페이스 파드 상태
kubectl get pods --all-namespaces

# 모든 서비스 상태
kubectl get svc --all-namespaces

# 노드 상태
kubectl get nodes
```

### 개별 애플리케이션 상태
```bash
# Rocket.Chat 상태
kubectl get pods -n rocketchat
kubectl get svc -n rocketchat
kubectl get hpa -n rocketchat

# 모니터링 상태
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

## 🛠️ 문제 해결

### SSH 연결 문제
```bash
# SSH 키 권한 확인
chmod 400 keys/rocketchat-key.pem

# SSH 연결 테스트
ssh -i ~/.ssh/rocketchat-key.pem ubuntu@$MASTER_IP 'echo "SSH connection successful"'
```

### k3s 서비스 문제
```bash
# k3s 서비스 상태 확인
sudo systemctl status k3s

# k3s 로그 확인
sudo journalctl -u k3s -f

# k3s 재시작
sudo systemctl restart k3s
```

### 파드 문제
```bash
# 파드 로그 확인
kubectl logs -f deployment/rocketchat -n rocketchat

# 파드 상세 정보 확인
kubectl describe pod <pod-name> -n rocketchat

# 파드 재시작
kubectl rollout restart deployment/rocketchat -n rocketchat
```

### 네트워크 문제
```bash
# 보안 그룹 확인
aws ec2 describe-security-groups --group-ids <security-group-id>

# 포트 리스닝 확인
sudo netstat -tlnp | grep 6443
sudo netstat -tlnp | grep 3000
```

## 📊 모니터링 설정

### Prometheus 설정
- **메트릭 수집**: 15초 간격
- **보존 기간**: 200시간
- **대상**: k3s 클러스터, Rocket.Chat 파드

### Grafana 설정
- **관리자 계정**: admin / admin123
- **대시보드**: Kubernetes 클러스터 메트릭
- **알림**: 이메일/Slack 연동 가능

## 🔒 보안 고려사항

### 네트워크 보안
- **보안 그룹**: 필요한 포트만 개방
- **VPC**: 프라이빗 서브넷 사용
- **NACL**: 추가 네트워크 보안

### 애플리케이션 보안
- **IAM Roles**: 최소 권한 원칙
- **Secrets**: Kubernetes Secrets 사용
- **RBAC**: 역할 기반 접근 제어

### 데이터 보안
- **암호화**: 전송 중 및 저장 시 암호화
- **백업**: 정기적인 데이터 백업
- **접근 제어**: 데이터베이스 접근 제한

## 🚨 백업 및 복구

### 데이터베이스 백업
```bash
# MongoDB 백업
kubectl exec -it <mongodb-pod> -- mongodump --out /backup

# Redis 백업
kubectl exec -it <redis-pod> -- redis-cli BGSAVE
```

### 설정 백업
```bash
# Kubernetes 리소스 백업
kubectl get all --all-namespaces -o yaml > k8s-backup.yaml

# ConfigMap 및 Secret 백업
kubectl get configmaps --all-namespaces -o yaml > configmaps-backup.yaml
kubectl get secrets --all-namespaces -o yaml > secrets-backup.yaml
```

## 📈 확장 및 최적화

### 수평 확장
```bash
# Worker 노드 추가
# 1. EC2 인스턴스 생성
# 2. k3s 에이전트 설치
# 3. 클러스터에 조인

# Rocket.Chat 파드 확장
kubectl scale deployment rocketchat --replicas=3 -n rocketchat
```

### 성능 최적화
- **리소스 제한**: CPU/메모리 제한 설정
- **HPA**: 자동 스케일링 설정
- **노드 선택**: 노드 셀렉터 사용

## 🧹 정리 및 삭제

### 애플리케이션 삭제
```bash
# Rocket.Chat 삭제
kubectl delete namespace rocketchat

# 모니터링 삭제
kubectl delete namespace monitoring
```

### 인프라 삭제
```bash
# Terraform으로 인프라 삭제
terraform destroy
```

## 📞 지원 및 문의

### 로그 수집
```bash
# 전체 클러스터 로그 수집
kubectl logs --all-containers=true --all-namespaces=true > cluster-logs.txt

# 시스템 로그 수집
journalctl -u k3s > k3s-logs.txt
```

### 문제 보고
1. 오류 메시지 수집
2. 로그 파일 수집
3. 환경 정보 수집
4. 재현 단계 작성

---

## 📝 체크리스트

### 설치 전 확인사항
- [ ] Terraform 인프라 배포 완료
- [ ] SSH 키 파일 존재 및 권한 설정
- [ ] 필요한 IP 주소 및 도메인 정보 수집
- [ ] 네트워크 연결 확인

### 설치 후 확인사항
- [ ] k3s 클러스터 정상 작동
- [ ] Prometheus 메트릭 수집 확인
- [ ] Grafana 대시보드 접속 확인
- [ ] Rocket.Chat 애플리케이션 접속 확인
- [ ] 모든 파드 정상 실행 확인

### 보안 확인사항
- [ ] 보안 그룹 설정 확인
- [ ] IAM 역할 및 정책 확인
- [ ] 데이터베이스 접근 제한 확인
- [ ] SSL/TLS 인증서 확인

---

**참고**: 이 매뉴얼은 기본적인 설치 과정을 다룹니다. 프로덕션 환경에서는 추가적인 보안 설정과 모니터링이 필요할 수 있습니다.
