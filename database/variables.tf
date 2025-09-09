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

variable "mongodb_ami" {
  description = "MongoDB용 AMI ID"
  type        = string
}

variable "mongodb_instance_type" {
  description = "MongoDB 인스턴스 타입"
  type        = string
}

variable "mongodb_volume_size" {
  description = "MongoDB 볼륨 크기"
  type        = number
}

variable "mongodb_security_group_id" {
  description = "MongoDB 보안 그룹 ID"
  type        = string
}

variable "private_subnet_1_id" {
  description = "프라이빗 서브넷 1 ID"
  type        = string
}

variable "redis_ami" {
  description = "Redis용 AMI ID"
  type        = string
}

variable "redis_instance_type" {
  description = "Redis 인스턴스 타입"
  type        = string
}

variable "redis_volume_size" {
  description = "Redis 볼륨 크기"
  type        = string
}

variable "redis_security_group_id" {
  description = "Redis 보안 그룹 ID"
  type        = string
}

variable "private_subnet_2_id" {
  description = "프라이빗 서브넷 2 ID"
  type        = string
}

variable "mongodb_version" {
  description = "MongoDB 버전"
  type        = string
}

variable "mongodb_data_volume_size" {
  description = "MongoDB 데이터 볼륨 크기"
  type        = number
}

variable "availability_zone_1" {
  description = "가용 영역 1"
  type        = string
}

variable "redis_version" {
  description = "Redis 버전"
  type        = string
}

variable "redis_data_volume_size" {
  description = "Redis 데이터 볼륨 크기"
  type        = number
}

variable "availability_zone_2" {
  description = "가용 영역 2"
  type        = string
}
