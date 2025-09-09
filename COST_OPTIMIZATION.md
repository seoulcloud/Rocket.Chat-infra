# 💰 Rocket.Chat FinOps 비용 최적화 가이드

## 🎯 프리티어 최적화 설정

### 📊 현재 인스턴스 구성 (프리티어 최적화)

| 컴포넌트 | 인스턴스 타입 | vCPU | RAM | 월 비용 (프리티어) | 용도 |
|---------|-------------|------|-----|------------------|------|
| k3s Master | t3.medium | 2 | 4GB | 무료 (750시간) | Kubernetes 마스터 |
| k3s Worker 1 | t3.medium | 2 | 4GB | 무료 (750시간) | Kubernetes 워커 |
| k3s Worker 2 | t3.medium | 2 | 4GB | 무료 (750시간) | Kubernetes 워커 |
| MongoDB | t3.small | 2 | 2GB | 무료 (750시간) | 데이터베이스 |
| Redis | t2.micro | 1 | 1GB | 무료 (750시간) | 캐시 |

### 💾 스토리지 최적화

| 볼륨 타입 | 크기 | 월 비용 (프리티어) | 용도 |
|----------|------|------------------|------|
| gp2 | 20GB | 무료 (30GB) | k3s 루트 볼륨 |
| gp2 | 20GB | 무료 (30GB) | MongoDB 루트 볼륨 |
| gp2 | 20GB | 무료 (30GB) | MongoDB 데이터 볼륨 |
| gp2 | 8GB | 무료 (30GB) | Redis 루트 볼륨 |
| gp2 | 8GB | 무료 (30GB) | Redis 데이터 볼륨 |

## 🚀 추가 비용 절감 방안

### 1. 인스턴스 최적화
```hcl
# 더 작은 인스턴스로 변경 가능 (성능 vs 비용 트레이드오프)
k3s_worker_instance_type = "t3.small"  # t3.medium → t3.small
mongodb_instance_type = "t2.micro"     # t3.small → t2.micro (단, 성능 저하 가능)
```

### 2. 볼륨 크기 최적화
```hcl
# 최소한의 볼륨 크기로 설정
k3s_volume_size = 8          # 20GB → 8GB
mongodb_volume_size = 8      # 20GB → 8GB
mongodb_data_volume_size = 8 # 20GB → 8GB
redis_volume_size = 8        # 8GB 유지
redis_data_volume_size = 8   # 8GB 유지
```

### 3. NAT Gateway 완전 제거 ✅
```hcl
# NAT Gateway와 EIP 완전 제거 (월 $45 절약)
# networking/route_table.tf에서 NAT Gateway 제거
# Private 서브넷을 Public으로 변경하여 직접 인터넷 접근
```

### 4. CloudFront 최적화
```hcl
# Price Class를 PriceClass_100으로 설정 (이미 적용됨)
# 가장 저렴한 지역만 사용
```

### 5. S3 스토리지 클래스 최적화
```hcl
# S3 버킷에 수명 주기 정책 적용
# Standard → IA → Glacier → Deep Archive
```

## 📈 모니터링 및 알림 설정

### 1. AWS Budget 설정
```bash
# AWS CLI로 예산 설정
aws budgets create-budget \
  --account-id YOUR_ACCOUNT_ID \
  --budget '{
    "BudgetName": "RocketChat-Monthly",
    "BudgetLimit": {
      "Amount": "10",
      "Unit": "USD"
    },
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST"
  }'
```

### 2. Cost Explorer 활성화
- AWS Cost Explorer에서 일일/월별 비용 추적
- 태그 기반 비용 분석

## 🔧 운영 최적화

### 1. 자동 스케일링
```hcl
# HPA 설정으로 필요시에만 리소스 확장
rocketchat_min_replicas = 1
rocketchat_max_replicas = 3  # 프리티어 제한
```

### 2. 스케줄링 기반 종료
```bash
# 개발 환경의 경우 야간/주말 자동 종료
# AWS Lambda + EventBridge로 스케줄링
```

### 3. 스팟 인스턴스 활용
```hcl
# 개발 환경에서 스팟 인스턴스 사용 (최대 90% 할인)
# 단, 프로덕션에서는 권장하지 않음
```

## 📊 예상 월 비용 (프리티어)

| 항목 | 프리티어 한도 | 예상 비용 |
|------|-------------|----------|
| EC2 인스턴스 | 750시간/월 | $0 |
| EBS 스토리지 | 30GB | $0 |
| NAT Gateway | - | $0 (제거됨) ✅ |
| ALB | - | $16 |
| CloudFront | 1TB 전송 | $0 |
| S3 | 5GB | $0 |
| **총 예상 비용** | | **$16/월** |

## 🎯 최종 최적화 권장사항

1. **NAT Gateway 완전 제거**: 월 $45 절약 ✅
2. **볼륨 크기 최소화**: 추가 스토리지 비용 절약
3. **개발 환경 야간 종료**: 50% 비용 절약
4. **스팟 인스턴스 활용**: 최대 90% 할인 (개발 환경만)

### 최종 예상 비용: $16/월 (ALB만 유료)
