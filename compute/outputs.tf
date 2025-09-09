# ALB 출력 제거

output "k3s_master_instance_id" {
  description = "k3s Master Instance ID"
  value       = aws_instance.k3s_master.id
}

output "k3s_master_public_ip" {
  description = "k3s Master Public IP"
  value       = aws_instance.k3s_master.public_ip
}

output "k3s_master_private_ip" {
  description = "k3s Master Private IP"
  value       = aws_instance.k3s_master.private_ip
}

output "k3s_worker_1_instance_id" {
  description = "k3s Worker 1 Instance ID"
  value       = aws_instance.k3s_worker_1.id
}

output "k3s_worker_1_public_ip" {
  description = "k3s Worker 1 Public IP"
  value       = aws_instance.k3s_worker_1.public_ip
}

output "k3s_worker_1_private_ip" {
  description = "k3s Worker 1 Private IP"
  value       = aws_instance.k3s_worker_1.private_ip
}

output "k3s_worker_2_instance_id" {
  description = "k3s Worker 2 Instance ID"
  value       = aws_instance.k3s_worker_2.id
}

output "k3s_worker_2_public_ip" {
  description = "k3s Worker 2 Public IP"
  value       = aws_instance.k3s_worker_2.public_ip
}

output "k3s_worker_2_private_ip" {
  description = "k3s Worker 2 Private IP"
  value       = aws_instance.k3s_worker_2.private_ip
}

output "k3s_worker_public_ips" {
  description = "k3s Worker Public IPs"
  value       = [aws_instance.k3s_worker_1.public_ip, aws_instance.k3s_worker_2.public_ip]
}

output "k3s_worker_private_ips" {
  description = "k3s Worker Private IPs"
  value       = [aws_instance.k3s_worker_1.private_ip, aws_instance.k3s_worker_2.private_ip]
} 