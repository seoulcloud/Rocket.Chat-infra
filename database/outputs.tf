output "mongodb_instance_id" {
  description = "MongoDB Instance ID"
  value       = aws_instance.mongodb.id
}

output "mongodb_private_ip" {
  description = "MongoDB Private IP"
  value       = aws_instance.mongodb.private_ip
}

output "mongodb_public_ip" {
  description = "MongoDB Public IP"
  value       = aws_instance.mongodb.public_ip
}

output "redis_instance_id" {
  description = "Redis Instance ID"
  value       = aws_instance.redis.id
}

output "redis_private_ip" {
  description = "Redis Private IP"
  value       = aws_instance.redis.private_ip
}

output "redis_public_ip" {
  description = "Redis Public IP"
  value       = aws_instance.redis.public_ip
}

output "mongodb_url" {
  description = "MongoDB Connection URL"
  value       = "mongodb://rocketchat:rocketchat123@${aws_instance.mongodb.private_ip}:27017/rocketchat?replicaSet=rs0"
  sensitive   = true
}

output "redis_url" {
  description = "Redis Connection URL"
  value       = "redis://:rocketchat123@${aws_instance.redis.private_ip}:6379"
  sensitive   = true
} 