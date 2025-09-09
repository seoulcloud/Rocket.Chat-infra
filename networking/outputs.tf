output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.rocketchat_vpc.id
}

output "vpc_cidr" {
  description = "VPC CIDR 블록"
  value       = aws_vpc.rocketchat_vpc.cidr_block
}

output "public_subnet_1_id" {
  description = "Public Subnet 1 ID"
  value       = aws_subnet.public_subnet_1.id
}

output "public_subnet_2_id" {
  description = "Public Subnet 2 ID"
  value       = aws_subnet.public_subnet_2.id
}

output "private_subnet_1_id" {
  description = "Private Subnet 1 ID"
  value       = aws_subnet.private_subnet_1.id
}

output "private_subnet_2_id" {
  description = "Private Subnet 2 ID"
  value       = aws_subnet.private_subnet_2.id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.rocketchat_igw.id
}

# NAT Gateway 제거로 인한 출력 제거 