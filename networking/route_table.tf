# NAT Gateway와 EIP 제거 - 비용 절약을 위해

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.rocketchat_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.rocketchat_igw.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
    Project     = "Rocket.Chat-FinOps"
    Type        = "Public"
  }
}

# Private Route Table 1 - NAT Gateway 없이 IGW로 직접 라우팅 (비용 절약)
resource "aws_route_table" "private_rt_1" {
  vpc_id = aws_vpc.rocketchat_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.rocketchat_igw.id
  }

  tags = {
    Name        = "${var.project_name}-private-rt-1"
    Environment = var.environment
    Project     = "Rocket.Chat-FinOps"
    Type        = "Private"
  }
}

# Private Route Table 2 - NAT Gateway 없이 IGW로 직접 라우팅 (비용 절약)
resource "aws_route_table" "private_rt_2" {
  vpc_id = aws_vpc.rocketchat_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.rocketchat_igw.id
  }

  tags = {
    Name        = "${var.project_name}-private-rt-2"
    Environment = var.environment
    Project     = "Rocket.Chat-FinOps"
    Type        = "Private"
  }
}

# Public Subnet 1 Route Table Association
resource "aws_route_table_association" "public_subnet_1_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

# Public Subnet 2 Route Table Association
resource "aws_route_table_association" "public_subnet_2_association" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# Private Subnet 1 Route Table Association
resource "aws_route_table_association" "private_subnet_1_association" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt_1.id
}

# Private Subnet 2 Route Table Association
resource "aws_route_table_association" "private_subnet_2_association" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt_2.id
}
