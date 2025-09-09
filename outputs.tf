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

# Key Pair 정보
output "key_pair_name" {
  description = "생성된 Key Pair 이름"
  value       = module.security.key_pair_name
}

output "private_key_path" {
  description = "Private Key 파일 경로"
  value       = module.security.private_key_path
}

output "public_key_path" {
  description = "Public Key 파일 경로"
  value       = module.security.public_key_path
}

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

# 액세스 정보 (CloudFront를 통한 접근)
output "rocketchat_access_url" {
  description = "Rocket.Chat 접근 URL (CloudFront)"
  value       = "https://${module.edge.cloudfront_domain_name}"
}

output "grafana_access_url" {
  description = "Grafana 접근 URL (k3s Master 직접 접근)"
  value       = "http://${module.compute.k3s_master_public_ip}:30000"
}

output "prometheus_access_url" {
  description = "Prometheus 접근 URL"
  value       = "http://${module.compute.k3s_master_public_ip}:30001"
}

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
  description = "SSH 접속 명령어"
  value = {
    master  = "ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${module.compute.k3s_master_public_ip}"
    worker1 = "ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${module.compute.k3s_worker_public_ips[0]}"
    worker2 = "ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${module.compute.k3s_worker_public_ips[1]}"
  }
} 