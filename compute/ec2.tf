# ALB 제거 - 직접 k3s 노드 접근

# k3s Master Node
resource "aws_instance" "k3s_master" {
  ami                    = var.k3s_ami
  instance_type          = var.k3s_master_instance_type
  key_name              = var.key_pair_name
  vpc_security_group_ids = [var.ec2_security_group_id]
  subnet_id             = var.public_subnet_1_id
  iam_instance_profile   = var.s3_access_instance_profile_name

  root_block_device {
    volume_type = "gp2"
    volume_size = var.k3s_volume_size
    encrypted   = true
  }

  user_data = base64encode(templatefile("${path.module}/k3s_master_user_data.sh", {
    mongodb_ip = var.mongodb_private_ip
    redis_ip   = var.redis_private_ip
  }))

  tags = {
    Name        = "${var.project_name}-k3s-master"
    Environment = var.environment
    Project     = "Rocket.Chat-FinOps"
    Role        = "k3s-master"
  }
}

# k3s Worker Node 1
resource "aws_instance" "k3s_worker_1" {
  ami                    = var.k3s_ami
  instance_type          = var.k3s_worker_instance_type
  key_name              = var.key_pair_name
  vpc_security_group_ids = [var.ec2_security_group_id]
  subnet_id             = var.public_subnet_2_id
  iam_instance_profile   = var.s3_access_instance_profile_name

  root_block_device {
    volume_type = "gp2"
    volume_size = var.k3s_volume_size
    encrypted   = true
  }

  user_data = base64encode(templatefile("${path.module}/k3s_worker_user_data.sh", {
    master_ip = aws_instance.k3s_master.private_ip
  }))

  depends_on = [aws_instance.k3s_master]

  tags = {
    Name        = "${var.project_name}-k3s-worker-1"
    Environment = var.environment
    Project     = "Rocket.Chat-FinOps"
    Role        = "k3s-worker"
  }
}

# k3s Worker Node 2
resource "aws_instance" "k3s_worker_2" {
  ami                    = var.k3s_ami
  instance_type          = var.k3s_worker_instance_type
  key_name              = var.key_pair_name
  vpc_security_group_ids = [var.ec2_security_group_id]
  subnet_id             = var.public_subnet_1_id
  iam_instance_profile   = var.s3_access_instance_profile_name

  root_block_device {
    volume_type = "gp2"
    volume_size = var.k3s_volume_size
    encrypted   = true
  }

  user_data = base64encode(templatefile("${path.module}/k3s_worker_user_data.sh", {
    master_ip = aws_instance.k3s_master.private_ip
  }))

  depends_on = [aws_instance.k3s_master]

  tags = {
    Name        = "${var.project_name}-k3s-worker-2"
    Environment = var.environment
    Project     = "Rocket.Chat-FinOps"
    Role        = "k3s-worker"
  }
}

# ALB Target Group Attachment 제거