# k3s 클러스터용 IAM 역할
resource "aws_iam_role" "k3s_cluster_role" {
  name = "${var.project_name}-k3s-cluster-role"

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
    Name        = "${var.project_name}-k3s-cluster-role"
    Environment = var.environment
    Project     = "Rocket.Chat-FinOps"
  }
}

# k3s 클러스터용 IAM 정책
resource "aws_iam_policy" "k3s_cluster_policy" {
  name        = "${var.project_name}-k3s-cluster-policy"
  description = "Policy for k3s cluster AWS access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
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
      },
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
      }
    ]
  })
}

# k3s 클러스터 역할에 정책 연결
resource "aws_iam_role_policy_attachment" "k3s_cluster_policy_attachment" {
  role       = aws_iam_role.k3s_cluster_role.name
  policy_arn = aws_iam_policy.k3s_cluster_policy.arn
}

# k3s 클러스터용 인스턴스 프로필
resource "aws_iam_instance_profile" "k3s_cluster_profile" {
  name = "${var.project_name}-k3s-cluster-profile"
  role = aws_iam_role.k3s_cluster_role.name

  tags = {
    Name        = "${var.project_name}-k3s-cluster-profile"
    Environment = var.environment
    Project     = "Rocket.Chat-FinOps"
  }
}

# OIDC Identity Provider for IRSA
resource "aws_iam_openid_connect_provider" "k3s_oidc" {
  url = "https://oidc.eks.${var.aws_region}.amazonaws.com/id/${var.k3s_cluster_id}"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "9e99a48a9960b14926bb7f3b02e22da2b0ab7280"
  ]

  tags = {
    Name        = "${var.project_name}-k3s-oidc"
    Environment = var.environment
    Project     = "Rocket.Chat-FinOps"
  }
}

# Rocket.Chat Service Account용 IAM 역할
resource "aws_iam_role" "rocketchat_service_account_role" {
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
            "${replace(aws_iam_openid_connect_provider.k3s_oidc.url, "https://", "")}:sub" = "system:serviceaccount:rocketchat:rocketchat"
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

# Rocket.Chat Service Account용 IAM 정책
resource "aws_iam_policy" "rocketchat_service_account_policy" {
  name        = "${var.project_name}-rocketchat-sa-policy"
  description = "Policy for Rocket.Chat Service Account"

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
      }
    ]
  })
}

# Rocket.Chat Service Account 역할에 정책 연결
resource "aws_iam_role_policy_attachment" "rocketchat_service_account_policy_attachment" {
  role       = aws_iam_role.rocketchat_service_account_role.name
  policy_arn = aws_iam_policy.rocketchat_service_account_policy.arn
}

# Prometheus Service Account용 IAM 역할
resource "aws_iam_role" "prometheus_service_account_role" {
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
            "${replace(aws_iam_openid_connect_provider.k3s_oidc.url, "https://", "")}:sub" = "system:serviceaccount:monitoring:prometheus"
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

# Prometheus Service Account용 IAM 정책
resource "aws_iam_policy" "prometheus_service_account_policy" {
  name        = "${var.project_name}-prometheus-sa-policy"
  description = "Policy for Prometheus Service Account"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_logs_bucket_arn,
          "${var.s3_logs_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Prometheus Service Account 역할에 정책 연결
resource "aws_iam_role_policy_attachment" "prometheus_service_account_policy_attachment" {
  role       = aws_iam_role.prometheus_service_account_role.name
  policy_arn = aws_iam_policy.prometheus_service_account_policy.arn
}
