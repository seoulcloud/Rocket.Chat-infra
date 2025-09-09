# VPC 생성
resource "aws_vpc" "rocketchat_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
    Project     = "Rocket.Chat-FinOps"
  }
}
