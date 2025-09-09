variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "k3s_master_ip" {
  description = "k3s Master IP"
  type        = string
}

variable "k3s_worker_ips" {
  description = "k3s Worker IP 목록"
  type        = list(string)
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
