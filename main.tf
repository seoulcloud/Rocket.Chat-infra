# Terraform 및 Provider 설정
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }
}

# AWS Provider 설정
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "Rocket.Chat-FinOps"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Kubernetes Provider 설정
provider "kubernetes" {
  host                   = "https://${data.aws_instance.k3s_master.public_ip}:6443"
  token                  = data.external.k3s_token.result.token
  cluster_ca_certificate = base64decode(data.external.k3s_token.result.certificate)
}

# Data Sources
data "aws_availability_zones" "available" {
  state = "available"
}

# Data Sources
data "aws_instance" "k3s_master" {
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-k3s-master"]
  }
  depends_on = [module.compute]
}

# k3s 설치 완료 대기
resource "time_sleep" "wait_for_k3s" {
  depends_on = [module.compute]
  create_duration = "120s"  # 2분 대기
}

data "external" "k3s_token" {
  program = ["bash", "-c", <<-EOT
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 -i ~/.ssh/${var.project_name}-key.pem ubuntu@${data.aws_instance.k3s_master.public_ip} '
      sudo cat /var/lib/rancher/k3s/server/node-token
    ' | jq -R '{token: ., certificate: "'"$(ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.project_name}-key.pem ubuntu@${data.aws_instance.k3s_master.public_ip} 'sudo cat /var/lib/rancher/k3s/server/tls/server-ca.crt | base64 -w 0')"'"}'
  EOT
  ]
  depends_on = [time_sleep.wait_for_k3s, module.security]
}

# 네트워킹 모듈
module "networking" {
  source = "./networking"

  project_name          = var.project_name
  environment           = var.environment
  aws_region            = var.aws_region
  vpc_cidr              = var.vpc_cidr
  public_subnet_1_cidr  = var.public_subnet_1_cidr
  public_subnet_2_cidr  = var.public_subnet_2_cidr
  private_subnet_1_cidr = var.private_subnet_1_cidr
  private_subnet_2_cidr = var.private_subnet_2_cidr
}

# 보안 그룹 모듈
module "security" {
  source = "./security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
  vpc_cidr     = var.vpc_cidr
}

# 데이터베이스 모듈
module "database" {
  source = "./database"

  project_name              = var.project_name
  environment               = var.environment
  key_pair_name             = module.security.key_pair_name
  mongodb_ami               = var.mongodb_ami
  mongodb_instance_type     = var.mongodb_instance_type
  mongodb_version           = var.mongodb_version
  mongodb_volume_size       = var.mongodb_volume_size
  mongodb_data_volume_size  = var.mongodb_data_volume_size
  mongodb_security_group_id = module.security.mongodb_security_group_id
  private_subnet_1_id       = module.networking.private_subnet_1_id
  availability_zone_1       = data.aws_availability_zones.available.names[0]
  redis_ami                 = var.redis_ami
  redis_instance_type       = var.redis_instance_type
  redis_version             = var.redis_version
  redis_volume_size         = var.redis_volume_size
  redis_data_volume_size    = var.redis_data_volume_size
  redis_security_group_id   = module.security.redis_security_group_id
  private_subnet_2_id       = module.networking.private_subnet_2_id
  availability_zone_2       = data.aws_availability_zones.available.names[1]
}

# 컴퓨팅 모듈
module "compute" {
  source = "./compute"

  project_name             = var.project_name
  environment              = var.environment
  key_pair_name            = module.security.key_pair_name
  k3s_ami                  = var.k3s_ami
  k3s_master_instance_type = var.k3s_master_instance_type
  k3s_worker_instance_type = var.k3s_worker_instance_type
  k3s_volume_size          = var.k3s_volume_size
  # ALB Security Group 제거
  ec2_security_group_id = module.security.ec2_security_group_id
  public_subnet_1_id    = module.networking.public_subnet_1_id
  public_subnet_2_id    = module.networking.public_subnet_2_id
  vpc_id                = module.networking.vpc_id
  mongodb_private_ip    = module.database.mongodb_private_ip
  redis_private_ip      = module.database.redis_private_ip
}

# k3s 모듈
module "k3s" {
  source = "./k3s"

  project_name   = var.project_name
  k3s_master_ip  = module.compute.k3s_master_private_ip
  k3s_worker_ips = module.compute.k3s_worker_private_ips
  mongodb_url    = module.database.mongodb_url
  redis_url      = module.database.redis_url
}

# 앱 모듈
module "apps" {
  source = "./apps"

  project_name                        = var.project_name
  environment                         = var.environment
  mongodb_url                         = module.database.mongodb_url
  redis_url                           = module.database.redis_url
  cloudfront_domain_name              = module.edge.cloudfront_domain_name
  rocketchat_replicas                 = var.rocketchat_replicas
  rocketchat_min_replicas             = var.rocketchat_min_replicas
  rocketchat_max_replicas             = var.rocketchat_max_replicas
  rocketchat_version                  = var.rocketchat_version
  prometheus_version                  = var.prometheus_version
  grafana_version                     = var.grafana_version
  grafana_admin_password              = var.grafana_admin_password
  rocketchat_service_account_role_arn = module.iam.rocketchat_service_account_role_arn
  prometheus_service_account_role_arn = module.iam.prometheus_service_account_role_arn
}

# 스토리지 모듈
module "storage" {
  source = "./storage"

  project_name = var.project_name
  environment  = var.environment
}

# IAM 모듈
module "iam" {
  source = "./iam"

  project_name          = var.project_name
  environment           = var.environment
  aws_region            = var.aws_region
  k3s_cluster_id        = "k3s-cluster"
  s3_files_bucket_arn   = module.storage.rocketchat_files_bucket_arn
  s3_logs_bucket_arn    = module.storage.rocketchat_logs_bucket_arn
  s3_backups_bucket_arn = module.storage.rocketchat_backups_bucket_arn
}

# 엣지 모듈
module "edge" {
  source = "./edge"

  project_name           = var.project_name
  environment           = var.environment
  k3s_master_public_ip  = module.compute.k3s_master_public_ip
  aws_region            = var.aws_region
  s3_bucket_arn         = module.storage.rocketchat_files_bucket_arn
  s3_bucket_domain_name = module.storage.rocketchat_files_bucket_domain_name
  s3_bucket_name        = module.storage.rocketchat_files_bucket_name
} 