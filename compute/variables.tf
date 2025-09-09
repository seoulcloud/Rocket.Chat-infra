variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경"
  type        = string
}

variable "key_pair_name" {
  description = "EC2 Key Pair 이름"
  type        = string
}

variable "k3s_ami" {
  description = "k3s용 AMI ID"
  type        = string
}

variable "k3s_master_instance_type" {
  description = "k3s Master 인스턴스 타입"
  type        = string
}

variable "k3s_worker_instance_type" {
  description = "k3s Worker 인스턴스 타입"
  type        = string
}

variable "k3s_volume_size" {
  description = "k3s 볼륨 크기"
  type        = number
}

variable "ec2_security_group_id" {
  description = "EC2 보안 그룹 ID"
  type        = string
}

variable "public_subnet_1_id" {
  description = "퍼블릭 서브넷 1 ID"
  type        = string
}

variable "public_subnet_2_id" {
  description = "퍼블릭 서브넷 2 ID"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "mongodb_private_ip" {
  description = "MongoDB 프라이빗 IP"
  type        = string
}

variable "redis_private_ip" {
  description = "Redis 프라이빗 IP"
  type        = string
}
