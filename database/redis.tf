# Redis EC2 Instance
resource "aws_instance" "redis" {
  ami                    = var.redis_ami
  instance_type          = var.redis_instance_type
  key_name              = var.key_pair_name
  vpc_security_group_ids = [var.redis_security_group_id]
  subnet_id             = var.private_subnet_1_id

  root_block_device {
    volume_type = "gp2"
    volume_size = var.redis_volume_size
    encrypted   = true
  }

  user_data = base64encode(templatefile("${path.module}/redis_user_data.sh", {
    redis_version = var.redis_version
  }))

  tags = {
    Name        = "${var.project_name}-redis"
    Environment = var.environment
    Project     = "Rocket.Chat-FinOps"
    Role        = "Cache"
  }
}

# Redis EBS Volume for Data Persistence
resource "aws_ebs_volume" "redis_data" {
  availability_zone = var.availability_zone_1
  size             = var.redis_data_volume_size
  type             = "gp2"
  encrypted        = true

  tags = {
    Name        = "${var.project_name}-redis-data"
    Environment = var.environment
    Project     = "Rocket.Chat-FinOps"
  }
}

# Attach Data Volume to Redis Instance
resource "aws_volume_attachment" "redis_data_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.redis_data.id
  instance_id = aws_instance.redis.id
}

# Redis User Data Script
resource "local_file" "redis_user_data" {
  content = templatefile("${path.module}/redis_user_data.sh", {
    redis_version = var.redis_version
  })
  filename = "${path.module}/redis_user_data.sh"
}
