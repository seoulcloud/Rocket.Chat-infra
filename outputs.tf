# Outputs for Rocket.Chat Infrastructure

# 네트워킹 출력
output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "public_subnet_1_id" {
  description = "Public Subnet 1 ID"
  value       = module.networking.public_subnet_1_id
}

output "public_subnet_2_id" {
  description = "Public Subnet 2 ID"
  value       = module.networking.public_subnet_2_id
}

output "private_subnet_1_id" {
  description = "Private Subnet 1 ID"
  value       = module.networking.private_subnet_1_id
}

output "private_subnet_2_id" {
  description = "Private Subnet 2 ID"
  value       = module.networking.private_subnet_2_id
}

# Key Pair 정보 제거 - 수동으로 생성된 키 페어 사용

# ALB 출력 제거

output "k3s_master_public_ip" {
  description = "k3s Master 퍼블릭 IP"
  value       = module.compute.k3s_master_public_ip
}

output "k3s_master_private_ip" {
  description = "k3s Master 프라이빗 IP"
  value       = module.compute.k3s_master_private_ip
}

output "k3s_worker_public_ips" {
  description = "k3s Worker 퍼블릭 IP 목록"
  value       = module.compute.k3s_worker_public_ips
}

output "k3s_worker_private_ips" {
  description = "k3s Worker 프라이빗 IP 목록"
  value       = module.compute.k3s_worker_private_ips
}

# 데이터베이스 출력
output "mongodb_private_ip" {
  description = "MongoDB 프라이빗 IP"
  value       = module.database.mongodb_private_ip
}

output "redis_private_ip" {
  description = "Redis 프라이빗 IP"
  value       = module.database.redis_private_ip
}

output "mongodb_url" {
  description = "MongoDB 연결 URL"
  value       = module.database.mongodb_url
  sensitive   = true
}

output "redis_url" {
  description = "Redis 연결 URL"
  value       = module.database.redis_url
  sensitive   = true
}

# 스토리지 출력
output "rocketchat_files_bucket_name" {
  description = "Rocket.Chat 파일 S3 버킷 이름"
  value       = module.storage.rocketchat_files_bucket_name
}

output "rocketchat_logs_bucket_name" {
  description = "Rocket.Chat 로그 S3 버킷 이름"
  value       = module.storage.rocketchat_logs_bucket_name
}

output "rocketchat_backups_bucket_name" {
  description = "Rocket.Chat 백업 S3 버킷 이름"
  value       = module.storage.rocketchat_backups_bucket_name
}

# 엣지 출력
output "cloudfront_distribution_id" {
  description = "CloudFront 배포 ID"
  value       = module.edge.cloudfront_distribution_id
}

output "cloudfront_domain_name" {
  description = "CloudFront 도메인 이름"
  value       = module.edge.cloudfront_domain_name
}

# 액세스 정보 제거 - AWS 리소스만 관리

# IAM 출력
output "k3s_oidc_provider_arn" {
  description = "k3s OIDC Provider ARN"
  value       = module.iam.k3s_oidc_provider_arn
}

output "rocketchat_service_account_role_arn" {
  description = "Rocket.Chat Service Account IAM Role ARN"
  value       = module.iam.rocketchat_service_account_role_arn
}

output "prometheus_service_account_role_arn" {
  description = "Prometheus Service Account IAM Role ARN"
  value       = module.iam.prometheus_service_account_role_arn
}

# SSH 접속 정보
output "ssh_connection_commands" {
  description = "SSH 접속 명령어 (수동으로 다운로드한 키 파일 사용)"
  value = {
    master  = "ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${module.compute.k3s_master_public_ip}"
    worker1 = "ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${module.compute.k3s_worker_public_ips[0]}"
    worker2 = "ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${module.compute.k3s_worker_public_ips[1]}"
  }
} 