# S3 Bucket for Rocket.Chat file uploads
resource "aws_s3_bucket" "rocketchat_files" {
  bucket = "${var.project_name}-rocketchat-files-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "${var.project_name}-rocketchat-files"
    Environment = var.environment
    Project     = "Rocket.Chat-FinOps"
  }
}

# Random string for bucket suffix
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 Bucket for logs
resource "aws_s3_bucket" "rocketchat_logs" {
  bucket = "${var.project_name}-rocketchat-logs-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "${var.project_name}-rocketchat-logs"
    Environment = var.environment
    Project     = "Rocket.Chat-FinOps"
  }
}

# S3 Bucket for backups
resource "aws_s3_bucket" "rocketchat_backups" {
  bucket = "${var.project_name}-rocketchat-backups-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "${var.project_name}-rocketchat-backups"
    Environment = var.environment
    Project     = "Rocket.Chat-FinOps"
  }
}

# S3 Bucket Versioning for files
resource "aws_s3_bucket_versioning" "rocketchat_files_versioning" {
  bucket = aws_s3_bucket.rocketchat_files.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Versioning for logs
resource "aws_s3_bucket_versioning" "rocketchat_logs_versioning" {
  bucket = aws_s3_bucket.rocketchat_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Versioning for backups
resource "aws_s3_bucket_versioning" "rocketchat_backups_versioning" {
  bucket = aws_s3_bucket.rocketchat_backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Server Side Encryption for files
resource "aws_s3_bucket_server_side_encryption_configuration" "rocketchat_files_encryption" {
  bucket = aws_s3_bucket.rocketchat_files.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Server Side Encryption for logs
resource "aws_s3_bucket_server_side_encryption_configuration" "rocketchat_logs_encryption" {
  bucket = aws_s3_bucket.rocketchat_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Server Side Encryption for backups
resource "aws_s3_bucket_server_side_encryption_configuration" "rocketchat_backups_encryption" {
  bucket = aws_s3_bucket.rocketchat_backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block for files
resource "aws_s3_bucket_public_access_block" "rocketchat_files_pab" {
  bucket = aws_s3_bucket.rocketchat_files.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Public Access Block for logs
resource "aws_s3_bucket_public_access_block" "rocketchat_logs_pab" {
  bucket = aws_s3_bucket.rocketchat_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Public Access Block for backups
resource "aws_s3_bucket_public_access_block" "rocketchat_backups_pab" {
  bucket = aws_s3_bucket.rocketchat_backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Lifecycle Configuration for logs
resource "aws_s3_bucket_lifecycle_configuration" "rocketchat_logs_lifecycle" {
  bucket = aws_s3_bucket.rocketchat_logs.id

  rule {
    id     = "log_retention"
    status = "Enabled"

    filter {}

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

# S3 Bucket Lifecycle Configuration for backups
resource "aws_s3_bucket_lifecycle_configuration" "rocketchat_backups_lifecycle" {
  bucket = aws_s3_bucket.rocketchat_backups.id

  rule {
    id     = "backup_retention"
    status = "Enabled"

    filter {}

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }
  }
}

# IAM Role for S3 Access
resource "aws_iam_role" "s3_access_role" {
  name = "${var.project_name}-s3-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-s3-access-role"
    Environment = var.environment
    Project     = "Rocket.Chat-FinOps"
  }
}

# IAM Policy for S3 Access
resource "aws_iam_policy" "s3_access_policy" {
  name        = "${var.project_name}-s3-access-policy"
  description = "Policy for S3 access from Rocket.Chat"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.rocketchat_files.arn,
          "${aws_s3_bucket.rocketchat_files.arn}/*",
          aws_s3_bucket.rocketchat_logs.arn,
          "${aws_s3_bucket.rocketchat_logs.arn}/*",
          aws_s3_bucket.rocketchat_backups.arn,
          "${aws_s3_bucket.rocketchat_backups.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeImages",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeRegions"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Role Policy Attachment
resource "aws_iam_role_policy_attachment" "s3_access_policy_attachment" {
  role       = aws_iam_role.s3_access_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "s3_access_profile" {
  name = "${var.project_name}-s3-access-profile"
  role = aws_iam_role.s3_access_role.name

  tags = {
    Name        = "${var.project_name}-s3-access-profile"
    Environment = var.environment
    Project     = "Rocket.Chat-FinOps"
  }
} 