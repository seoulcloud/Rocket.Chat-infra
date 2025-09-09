# Public Subnet 1
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.rocketchat_vpc.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet-1"
    Environment = var.environment
    Project     = "Rocket.Chat-FinOps"
    Type        = "Public"
  }
}

# Public Subnet 2
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.rocketchat_vpc.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet-2"
    Environment = var.environment
    Project     = "Rocket.Chat-FinOps"
    Type        = "Public"
  }
}

# Private Subnet 1 - NAT Gateway 제거로 인해 Public으로 변경 (비용 절약)
resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = aws_vpc.rocketchat_vpc.id
  cidr_block              = var.private_subnet_1_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-private-subnet-1"
    Environment = var.environment
    Project     = "Rocket.Chat-FinOps"
    Type        = "Public"
  }
}

# Private Subnet 2 - NAT Gateway 제거로 인해 Public으로 변경 (비용 절약)
resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = aws_vpc.rocketchat_vpc.id
  cidr_block              = var.private_subnet_2_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-private-subnet-2"
    Environment = var.environment
    Project     = "Rocket.Chat-FinOps"
    Type        = "Public"
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}
