variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경"
  type        = string
}

variable "k3s_master_public_ip" {
  description = "k3s Master 노드 퍼블릭 IP"
  type        = string
}

variable "aws_region" {
  description = "AWS 리전"
  type        = string
}

variable "s3_bucket_arn" {
  description = "S3 버킷 ARN"
  type        = string
}

variable "s3_bucket_domain_name" {
  description = "S3 버킷 도메인 이름"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 버킷 이름"
  type        = string
}
