variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경"
  type        = string
}

variable "mongodb_url" {
  description = "MongoDB 연결 URL"
  type        = string
  sensitive   = true
}

variable "redis_url" {
  description = "Redis 연결 URL"
  type        = string
  sensitive   = true
}

variable "cloudfront_domain_name" {
  description = "CloudFront 도메인 이름"
  type        = string
}

variable "rocketchat_replicas" {
  description = "Rocket.Chat 초기 복제본 수"
  type        = number
}

variable "rocketchat_min_replicas" {
  description = "Rocket.Chat 최소 복제본 수"
  type        = number
}

variable "rocketchat_max_replicas" {
  description = "Rocket.Chat 최대 복제본 수"
  type        = number
}

variable "rocketchat_version" {
  description = "Rocket.Chat 버전"
  type        = string
}

variable "prometheus_version" {
  description = "Prometheus 버전"
  type        = string
}

variable "grafana_version" {
  description = "Grafana 버전"
  type        = string
}

variable "grafana_admin_password" {
  description = "Grafana 관리자 비밀번호"
  type        = string
  sensitive   = true
}

variable "rocketchat_service_account_role_arn" {
  description = "Rocket.Chat Service Account IAM Role ARN"
  type        = string
}

variable "prometheus_service_account_role_arn" {
  description = "Prometheus Service Account IAM Role ARN"
  type        = string
}
