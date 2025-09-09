# CloudFront Origin Access Control
resource "aws_cloudfront_origin_access_control" "rocketchat_oac" {
  name                              = "${var.project_name}-oac"
  description                       = "OAC for Rocket.Chat S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution for Rocket.Chat
resource "aws_cloudfront_distribution" "rocketchat_distribution" {
  origin {
    domain_name              = var.s3_bucket_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.rocketchat_oac.id
    origin_id                = "S3-${var.s3_bucket_name}"
  }

  # k3s Master 노드 오리진 추가 (DNS 사용)
  origin {
    domain_name = "${var.k3s_master_public_ip}.ec2.${var.aws_region}.amazonaws.com"
    origin_id   = "k3s-master-${var.project_name}"

    custom_origin_config {
      http_port              = 30000
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for Rocket.Chat"
  default_root_object = "index.html"

  # 기본 캐시 동작 - k3s Master 노드로 라우팅
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "k3s-master-${var.project_name}"

    forwarded_values {
      query_string = true
      headers      = ["Host", "Authorization", "CloudFront-Forwarded-Proto"]
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  # Cache behavior for static files
  ordered_cache_behavior {
    path_pattern     = "/assets/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.s3_bucket_name}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
  }

  # Cache behavior for uploads
  ordered_cache_behavior {
    path_pattern     = "/file-upload/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.s3_bucket_name}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "${var.project_name}-cloudfront"
    Environment = var.environment
    Project     = "Rocket.Chat-FinOps"
  }
}

# S3 Bucket Policy for CloudFront
resource "aws_s3_bucket_policy" "rocketchat_files_policy" {
  bucket = var.s3_bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${var.s3_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.rocketchat_distribution.arn
          }
        }
      }
    ]
  })
}

# CloudFront Cache Policy for static content
resource "aws_cloudfront_cache_policy" "static_content_policy" {
  name        = "${var.project_name}-static-content-policy"
  comment     = "Cache policy for static content"
  default_ttl = 86400
  max_ttl     = 31536000
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    query_strings_config {
      query_string_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    cookies_config {
      cookie_behavior = "none"
    }
  }
}

# CloudFront Response Headers Policy
resource "aws_cloudfront_response_headers_policy" "security_headers_policy" {
  name    = "${var.project_name}-security-headers-policy"
  comment = "Security headers policy for Rocket.Chat"

  security_headers_config {
    content_type_options {
      override = false
    }
    frame_options {
      frame_option = "DENY"
      override     = false
    }
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = false
    }
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = false
    }
  }

  custom_headers_config {
    items {
      header   = "X-Robots-Tag"
      value    = "noindex, nofollow"
      override = false
    }
  }
} 