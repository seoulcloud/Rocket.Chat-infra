output "rocketchat_files_bucket_name" {
  description = "Rocket.Chat Files S3 Bucket Name"
  value       = aws_s3_bucket.rocketchat_files.bucket
}

output "rocketchat_files_bucket_arn" {
  description = "Rocket.Chat Files S3 Bucket ARN"
  value       = aws_s3_bucket.rocketchat_files.arn
}

output "s3_files_bucket_arn" {
  description = "S3 Files Bucket ARN (alias)"
  value       = aws_s3_bucket.rocketchat_files.arn
}

output "rocketchat_logs_bucket_name" {
  description = "Rocket.Chat Logs S3 Bucket Name"
  value       = aws_s3_bucket.rocketchat_logs.bucket
}

output "rocketchat_logs_bucket_arn" {
  description = "Rocket.Chat Logs S3 Bucket ARN"
  value       = aws_s3_bucket.rocketchat_logs.arn
}

output "s3_logs_bucket_arn" {
  description = "S3 Logs Bucket ARN (alias)"
  value       = aws_s3_bucket.rocketchat_logs.arn
}

output "rocketchat_backups_bucket_name" {
  description = "Rocket.Chat Backups S3 Bucket Name"
  value       = aws_s3_bucket.rocketchat_backups.bucket
}

output "rocketchat_backups_bucket_arn" {
  description = "Rocket.Chat Backups S3 Bucket ARN"
  value       = aws_s3_bucket.rocketchat_backups.arn
}

output "s3_backups_bucket_arn" {
  description = "S3 Backups Bucket ARN (alias)"
  value       = aws_s3_bucket.rocketchat_backups.arn
}

output "s3_access_role_arn" {
  description = "S3 Access IAM Role ARN"
  value       = aws_iam_role.s3_access_role.arn
}

output "s3_access_instance_profile_name" {
  description = "S3 Access IAM Instance Profile Name"
  value       = aws_iam_instance_profile.s3_access_profile.name
}

output "rocketchat_files_bucket_domain_name" {
  description = "Rocket.Chat Files S3 Bucket Domain Name"
  value       = aws_s3_bucket.rocketchat_files.bucket_regional_domain_name
}
