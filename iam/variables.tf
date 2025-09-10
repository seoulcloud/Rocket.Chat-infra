variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경"
  type        = string
}

variable "aws_region" {
  description = "AWS 리전"
  type        = string
}

variable "k3s_cluster_id" {
  description = "k3s 클러스터 ID"
  type        = string
  default     = "k3s-cluster"
}

variable "s3_files_bucket_arn" {
  description = "S3 Files 버킷 ARN"
  type        = string
}

variable "s3_logs_bucket_arn" {
  description = "S3 Logs 버킷 ARN"
  type        = string
}

variable "s3_backups_bucket_arn" {
  description = "S3 Backups 버킷 ARN"
  type        = string
}
