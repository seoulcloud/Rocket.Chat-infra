output "k3s_cluster_role_arn" {
  description = "k3s 클러스터 IAM 역할 ARN"
  value       = aws_iam_role.k3s_cluster_role.arn
}

output "k3s_cluster_instance_profile_name" {
  description = "k3s 클러스터 IAM 인스턴스 프로필 이름"
  value       = aws_iam_instance_profile.k3s_cluster_profile.name
}

output "k3s_oidc_provider_arn" {
  description = "k3s OIDC Provider ARN"
  value       = aws_iam_openid_connect_provider.k3s_oidc.arn
}

output "rocketchat_service_account_role_arn" {
  description = "Rocket.Chat Service Account IAM 역할 ARN"
  value       = aws_iam_role.rocketchat_service_account_role.arn
}

output "prometheus_service_account_role_arn" {
  description = "Prometheus Service Account IAM 역할 ARN"
  value       = aws_iam_role.prometheus_service_account_role.arn
}
