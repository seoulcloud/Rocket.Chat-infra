# Internet Gateway
resource "aws_internet_gateway" "rocketchat_igw" {
  vpc_id = aws_vpc.rocketchat_vpc.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
    Project     = "Rocket.Chat-FinOps"
  }
}
