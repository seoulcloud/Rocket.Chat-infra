# EC2 Key Pair 생성
resource "aws_key_pair" "rocketchat_key" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.rocketchat_key.public_key_openssh

  tags = {
    Name        = "${var.project_name}-key"
    Environment = var.environment
    Project     = "Rocket.Chat-FinOps"
  }
}

# TLS Private Key 생성
resource "tls_private_key" "rocketchat_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 로컬 사용자 SSH 디렉터리 준비
resource "null_resource" "prepare_ssh_dir" {
  provisioner "local-exec" {
    command = "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
  }
}

# Private Key를 로컬 파일로 저장
resource "local_file" "rocketchat_private_key" {
  content  = tls_private_key.rocketchat_key.private_key_pem
  filename = "~/.ssh/${var.project_name}-key.pem"

  file_permission = "0400"

  depends_on = [tls_private_key.rocketchat_key, null_resource.prepare_ssh_dir]
}

# Public Key를 로컬 파일로 저장
resource "local_file" "rocketchat_public_key" {
  content  = tls_private_key.rocketchat_key.public_key_openssh
  filename = "~/.ssh/${var.project_name}-key.pub"

  file_permission = "0644"

  depends_on = [tls_private_key.rocketchat_key, null_resource.prepare_ssh_dir]
}
