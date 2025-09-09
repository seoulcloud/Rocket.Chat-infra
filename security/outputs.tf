# Key Pair 출력
output "key_pair_name" {
  description = "생성된 Key Pair 이름"
  value       = aws_key_pair.rocketchat_key.key_name
}

output "private_key_path" {
  description = "Private Key 파일 경로"
  value       = local_file.rocketchat_private_key.filename
}

output "public_key_path" {
  description = "Public Key 파일 경로"
  value       = local_file.rocketchat_public_key.filename
}

# ALB Security Group 출력 제거

output "ec2_security_group_id" {
  description = "EC2 Security Group ID"
  value       = aws_security_group.ec2_sg.id
}

output "mongodb_security_group_id" {
  description = "MongoDB Security Group ID"
  value       = aws_security_group.mongodb_sg.id
}

output "redis_security_group_id" {
  description = "Redis Security Group ID"
  value       = aws_security_group.redis_sg.id
}

output "prometheus_security_group_id" {
  description = "Prometheus Security Group ID"
  value       = aws_security_group.prometheus_sg.id
}

output "grafana_security_group_id" {
  description = "Grafana Security Group ID"
  value       = aws_security_group.grafana_sg.id
} 