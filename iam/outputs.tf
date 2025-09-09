output "k3s_oidc_provider_arn" {
  description = "k3s OIDC Provider ARN"
  value       = aws_iam_openid_connect_provider.k3s_oidc.arn
}

output "k3s_oidc_provider_url" {
  description = "k3s OIDC Provider URL"
  value       = aws_iam_openid_connect_provider.k3s_oidc.url
}

output "rocketchat_service_account_role_arn" {
  description = "Rocket.Chat Service Account IAM Role ARN"
  value       = aws_iam_role.rocketchat_service_account.arn
}

output "prometheus_service_account_role_arn" {
  description = "Prometheus Service Account IAM Role ARN"
  value       = aws_iam_role.prometheus_service_account.arn
}

output "rocketchat_service_account_role_name" {
  description = "Rocket.Chat Service Account IAM Role Name"
  value       = aws_iam_role.rocketchat_service_account.name
}

output "prometheus_service_account_role_name" {
  description = "Prometheus Service Account IAM Role Name"
  value       = aws_iam_role.prometheus_service_account.name
}
