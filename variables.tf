# 프로젝트 기본 설정
variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "rocketchat"
}

variable "environment" {
  description = "환경 (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

# 네트워킹 설정
variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "Public Subnet 1 CIDR"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "Public Subnet 2 CIDR"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_1_cidr" {
  description = "Private Subnet 1 CIDR"
  type        = string
  default     = "10.0.3.0/24"
}

variable "private_subnet_2_cidr" {
  description = "Private Subnet 2 CIDR"
  type        = string
  default     = "10.0.4.0/24"
}

# EC2 설정
variable "key_pair_name" {
  description = "EC2 Key Pair 이름 (자동 생성됨)"
  type        = string
  default     = "rocketchat-key"
}

# MongoDB 설정
variable "mongodb_ami" {
  description = "MongoDB EC2 AMI ID"
  type        = string
  default     = "ami-0c76973fbe0ee100c" # Ubuntu 20.04 LTS
}

variable "mongodb_instance_type" {
  description = "MongoDB EC2 인스턴스 타입"
  type        = string
  default     = "t3.small"
}

variable "mongodb_version" {
  description = "MongoDB 버전"
  type        = string
  default     = "6.0"
}

variable "mongodb_volume_size" {
  description = "MongoDB 루트 볼륨 크기 (GB)"
  type        = number
  default     = 20
}

variable "mongodb_data_volume_size" {
  description = "MongoDB 데이터 볼륨 크기 (GB)"
  type        = number
  default     = 50
}

# Redis 설정
variable "redis_ami" {
  description = "Redis EC2 AMI ID"
  type        = string
  default     = "ami-0c76973fbe0ee100c" # Ubuntu 20.04 LTS
}

variable "redis_instance_type" {
  description = "Redis EC2 인스턴스 타입"
  type        = string
  default     = "t2.micro"
}

variable "redis_version" {
  description = "Redis 버전"
  type        = string
  default     = "7.0"
}

variable "redis_volume_size" {
  description = "Redis 루트 볼륨 크기 (GB)"
  type        = number
  default     = 20
}

variable "redis_data_volume_size" {
  description = "Redis 데이터 볼륨 크기 (GB)"
  type        = number
  default     = 20
}

# k3s 설정
variable "k3s_ami" {
  description = "k3s EC2 AMI ID"
  type        = string
  default     = "ami-0c76973fbe0ee100c" # Ubuntu 20.04 LTS
}

variable "k3s_master_instance_type" {
  description = "k3s Master 인스턴스 타입"
  type        = string
  default     = "t3.medium"
}

variable "k3s_worker_instance_type" {
  description = "k3s Worker 인스턴스 타입"
  type        = string
  default     = "t3.medium"
}

variable "k3s_volume_size" {
  description = "k3s 루트 볼륨 크기 (GB)"
  type        = number
  default     = 30
}

# Rocket.Chat 및 모니터링 설정 제거 - AWS 리소스만 관리

# k3s API 서버 접근 설정
variable "k3s_api_server_cidr" {
  description = "k3s API 서버 접근 허용 CIDR 블록 (기본값: 모든 IP 허용)"
  type        = string
  default     = "0.0.0.0/0"
}