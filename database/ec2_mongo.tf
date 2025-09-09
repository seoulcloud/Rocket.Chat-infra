# MongoDB EC2 Instance
resource "aws_instance" "mongodb" {
  ami                    = var.mongodb_ami
  instance_type          = var.mongodb_instance_type
  key_name              = var.key_pair_name
  vpc_security_group_ids = [var.mongodb_security_group_id]
  subnet_id             = var.private_subnet_1_id

  root_block_device {
    volume_type = "gp2"
    volume_size = var.mongodb_volume_size
    encrypted   = true
  }

  user_data = base64encode(templatefile("${path.module}/mongodb_user_data.sh", {
    mongodb_version = var.mongodb_version
  }))

  tags = {
    Name        = "${var.project_name}-mongodb"
    Environment = var.environment
    Project     = "Rocket.Chat-FinOps"
    Role        = "Database"
  }
}

# MongoDB EBS Volume for Data Persistence
resource "aws_ebs_volume" "mongodb_data" {
  availability_zone = var.availability_zone_1
  size             = var.mongodb_data_volume_size
  type             = "gp2"
  encrypted        = true

  tags = {
    Name        = "${var.project_name}-mongodb-data"
    Environment = var.environment
    Project     = "Rocket.Chat-FinOps"
  }
}

# Attach Data Volume to MongoDB Instance
resource "aws_volume_attachment" "mongodb_data_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.mongodb_data.id
  instance_id = aws_instance.mongodb.id
}

# MongoDB User Data Script
resource "local_file" "mongodb_user_data" {
  content = templatefile("${path.module}/mongodb_user_data.sh", {
    mongodb_version = var.mongodb_version
  })
  filename = "${path.module}/mongodb_user_data.sh"
}