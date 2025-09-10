# Key Pair 출력 - 수동 생성된 키 페어 사용
output "key_pair_name" {
  description = "사용할 Key Pair 이름 (수동 생성)"
  value       = "${var.project_name}-key"
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