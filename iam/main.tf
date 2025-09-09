# IAM 모듈 - IRSA 및 EC2 IAM Role 관리

# OIDC Provider for k3s cluster (IRSA)
resource "aws_iam_openid_connect_provider" "k3s_oidc" {
  url = "https://oidc.eks.${var.aws_region}.amazonaws.com/id/${var.k3s_cluster_id}"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "9e99a48a9960b14926bb7f3b02e22da2b0ab7280", # EKS OIDC thumbprint
  ]

  tags = {
    Name        = "${var.project_name}-k3s-oidc"
    Environment = var.environment
    Project     = "Rocket.Chat-FinOps"
  }
}

# IAM Role for Rocket.Chat Service Account (IRSA)
resource "aws_iam_role" "rocketchat_service_account" {
  name = "${var.project_name}-rocketchat-sa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.k3s_oidc.arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.k3s_oidc.url, "https://", "")}:sub" = "system:serviceaccount:rocketchat:rocketchat-sa"
            "${replace(aws_iam_openid_connect_provider.k3s_oidc.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-rocketchat-sa-role"
    Environment = var.environment
    Project     = "Rocket.Chat-FinOps"
  }
}

# IAM Policy for Rocket.Chat Service Account
resource "aws_iam_policy" "rocketchat_service_account_policy" {
  name        = "${var.project_name}-rocketchat-sa-policy"
  description = "Policy for Rocket.Chat Service Account to access AWS services"

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
          var.s3_files_bucket_arn,
          "${var.s3_files_bucket_arn}/*",
          var.s3_logs_bucket_arn,
          "${var.s3_logs_bucket_arn}/*",
          var.s3_backups_bucket_arn,
          "${var.s3_backups_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}-*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach policy to Rocket.Chat Service Account role
resource "aws_iam_role_policy_attachment" "rocketchat_service_account_policy" {
  role       = aws_iam_role.rocketchat_service_account.name
  policy_arn = aws_iam_policy.rocketchat_service_account_policy.arn
}

# IAM Role for Prometheus Service Account (IRSA)
resource "aws_iam_role" "prometheus_service_account" {
  name = "${var.project_name}-prometheus-sa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.k3s_oidc.arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.k3s_oidc.url, "https://", "")}:sub" = "system:serviceaccount:monitoring:prometheus-sa"
            "${replace(aws_iam_openid_connect_provider.k3s_oidc.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-prometheus-sa-role"
    Environment = var.environment
    Project     = "Rocket.Chat-FinOps"
  }
}

# IAM Policy for Prometheus Service Account
resource "aws_iam_policy" "prometheus_service_account_policy" {
  name        = "${var.project_name}-prometheus-sa-policy"
  description = "Policy for Prometheus Service Account to access AWS services"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach policy to Prometheus Service Account role
resource "aws_iam_role_policy_attachment" "prometheus_service_account_policy" {
  role       = aws_iam_role.prometheus_service_account.name
  policy_arn = aws_iam_policy.prometheus_service_account_policy.arn
}

# Data source for current AWS account ID
data "aws_caller_identity" "current" {}
