# main.tf

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      {
        Project     = var.project_name
        Environment = var.environment
        ManagedBy   = "Terraform"
        Solution    = "live-streaming-on-aws"
      },
      var.tags
    )
  }
}

# Generate random string for unique resource names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

locals {
  resource_prefix = "${var.project_name}-${var.environment}"
  unique_id       = random_string.suffix.result
  
  encoding_profiles = {
    "1080" = ["1920x1080", "1280x720", "960x540", "768x432", "640x360", "512x288"]
    "720"  = ["1280x720", "960x540", "768x432", "640x360", "512x288"]
    "540"  = ["960x540", "768x432", "640x360", "512x288"]
  }
}

# ==========================================
# S3 Bucket for Artifacts and Demo Player
# ==========================================

resource "aws_s3_bucket" "live_streaming_bucket" {
  bucket = var.s3_bucket_name
}

resource "aws_s3_bucket_public_access_block" "live_streaming_bucket_pab" {
  bucket = aws_s3_bucket.live_streaming_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "live_streaming_bucket_versioning" {
  bucket = aws_s3_bucket.live_streaming_bucket.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "live_streaming_bucket_encryption" {
  bucket = aws_s3_bucket.live_streaming_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CloudFront Logging Bucket (optional)
resource "aws_s3_bucket" "cloudfront_logs" {
  count  = var.enable_cloudfront_logging ? 1 : 0
  bucket = "${var.s3_bucket_name}-cloudfront-logs"
}

resource "aws_s3_bucket_ownership_controls" "cloudfront_logs_ownership" {
  count  = var.enable_cloudfront_logging ? 1 : 0
  bucket = aws_s3_bucket.cloudfront_logs[0].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# ==========================================
# IAM Roles and Policies
# ==========================================

# MediaLive IAM Role
resource "aws_iam_role" "medialive_role" {
  name = "${local.resource_prefix}-medialive-role-${local.unique_id}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "medialive.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "medialive_policy" {
  name = "${local.resource_prefix}-medialive-policy"
  role = aws_iam_role.medialive_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "mediapackage:DescribeChannel"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "mediaconnect:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# ==========================================
# MediaPackage Channel
# ==========================================

resource "aws_media_package_channel" "live_streaming_package" {
  channel_id  = "${local.resource_prefix}-channel-${local.unique_id}"
  description = "Live streaming MediaPackage channel for ${var.project_name}"
}

# ==========================================
# NOTE: MediaPackage Origin Endpoints
# ==========================================
# MediaPackage V1 Origin Endpoints are not yet supported in Terraform AWS provider.
# You have three options:
#
# 1. Create them manually via AWS Console after running terraform apply
# 2. Use AWS CLI to create them (see create_endpoints.sh script)
# 3. Wait for AWS provider support (tracking issue in GitHub)
#
# The MediaPackage channel has been created and you can reference:
#   - Channel ID: aws_media_package_channel.live_streaming_package.id
#   - HLS Ingest URLs: aws_media_package_channel.live_streaming_package.hls_ingest
#
# After creating origin endpoints manually, you can import them:
#   terraform import module.live_streaming.null_resource.hls_endpoint <endpoint-id>

# ==========================================
# CDN Authorization (Optional)
# ==========================================

resource "aws_secretsmanager_secret" "cdn_secret" {
  count       = var.enable_cdn_authorization ? 1 : 0
  name_prefix = "${local.resource_prefix}-cdn-secret-"
  description = "CDN authorization secret for MediaPackage"
}

resource "aws_secretsmanager_secret_version" "cdn_secret_version" {
  count     = var.enable_cdn_authorization ? 1 : 0
  secret_id = aws_secretsmanager_secret.cdn_secret[0].id
  secret_string = jsonencode({
    cdn_identifier = random_string.suffix.result
  })
}

resource "aws_iam_role" "mediapackage_secrets_role" {
  count = var.enable_cdn_authorization ? 1 : 0
  name  = "${local.resource_prefix}-mediapackage-secrets-${local.unique_id}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "mediapackage.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "mediapackage_secrets_policy" {
  count = var.enable_cdn_authorization ? 1 : 0
  name  = "${local.resource_prefix}-mediapackage-secrets-policy"
  role  = aws_iam_role.mediapackage_secrets_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.cdn_secret[0].arn
      }
    ]
  })
}

# ==========================================
# MediaLive Input Security Group
# ==========================================

resource "aws_medialive_input_security_group" "live_streaming_sg" {
  count = var.input_type == "RTMP_PUSH" || var.input_type == "RTP_PUSH" ? 1 : 0
  
  whitelist_rules {
    cidr = var.input_security_group_whitelist[0]
  }

  tags = {
    Name = "${local.resource_prefix}-input-sg"
  }
}

# ==========================================
# MediaLive Input
# ==========================================

resource "aws_medialive_input" "live_streaming_input" {
  name                  = "${local.resource_prefix}-input-${local.unique_id}"
  input_security_groups = var.input_type == "RTMP_PUSH" || var.input_type == "RTP_PUSH" ? [aws_medialive_input_security_group.live_streaming_sg[0].id] : []
  type                  = var.input_type

  dynamic "destinations" {
    for_each = var.input_type == "RTMP_PUSH" ? (var.channel_class == "STANDARD" ? [1, 2] : [1]) : []
    content {
      stream_name = "${local.resource_prefix}/primary"
    }
  }

  tags = {
    Name = "${local.resource_prefix}-input"
  }
}

# ==========================================
# MediaLive Channel
# ==========================================

resource "aws_medialive_channel" "live_streaming_channel" {
  name          = "${local.resource_prefix}-channel-${local.unique_id}"
  channel_class = var.channel_class
  role_arn      = aws_iam_role.medialive_role.arn

  input_specification {
    codec            = var.input_codec
    maximum_bitrate  = "MAX_20_MBPS"
    input_resolution = var.encoding_profile == "1080" ? "HD" : (var.encoding_profile == "720" ? "HD" : "SD")
  }

  destinations {
    id = "mediapackage-destination"

    media_package_settings {
      channel_id = aws_media_package_channel.live_streaming_package.id
    }
  }

  encoder_settings {
    timecode_config {
      source = "EMBEDDED"
    }

    audio_descriptions {
      audio_selector_name = "default"
      name                = "audio_1"
      codec_settings {
        aac_settings {
          bitrate         = 96000
          coding_mode     = "CODING_MODE_2_0"
          input_type      = "NORMAL"
          profile         = "LC"
          raw_format      = "NONE"
          sample_rate     = 48000
          spec            = "MPEG4"
        }
      }
    }

    # Required output_groups block
    output_groups {
      output_group_settings {
        media_package_group_settings {
          destination {
            destination_ref_id = "mediapackage-destination"
          }
        }
      }

      outputs {
        output_name             = "HD-1080p"
        video_description_name  = "video_1080p"
        audio_description_names = ["audio_1"]
        output_settings {
          media_package_output_settings {}
        }
      }
    }

    # Video descriptions for the outputs
    video_descriptions {
      name              = "video_1080p"
      respond_to_afd    = "NONE"
      scaling_behavior  = "DEFAULT"
      sharpness         = 50
      
      codec_settings {
        h264_settings {
          adaptive_quantization = "HIGH"
          bitrate              = 5000000
          buf_size             = 10000000
          color_metadata       = "INSERT"
          entropy_encoding     = "CABAC"
          framerate_control    = "SPECIFIED"
          framerate_numerator  = 30
          framerate_denominator = 1
          gop_b_reference      = "ENABLED"
          gop_closed_cadence   = 1
          gop_num_b_frames     = 3
          gop_size             = 60
          gop_size_units       = "FRAMES"
          level                = "H264_LEVEL_4_1"
          look_ahead_rate_control = "HIGH"
          num_ref_frames       = 3
          par_control          = "SPECIFIED"
          profile              = "HIGH"
          rate_control_mode    = "CBR"
          scene_change_detect  = "ENABLED"
          spatial_aq           = "ENABLED"
          syntax               = "DEFAULT"
          temporal_aq          = "ENABLED"
          timecode_insertion   = "DISABLED"
        }
      }
      
      height = 1080
      width  = 1920
    }
  }

  input_attachments {
    input_attachment_name = "input-attachment"
    input_id              = aws_medialive_input.live_streaming_input.id

    input_settings {
      source_end_behavior = "CONTINUE"

      audio_selector {
        name = "default"

        selector_settings {
          audio_pid_selection {
            pid = 1  # Added required Pid field
          }
        }
      }
    }
  }

  tags = {
    Name = "${local.resource_prefix}-channel"
  }
}

# ==========================================
# CloudFront Distribution
# ==========================================
# Note: This will need to be updated with origin endpoints after they are created

resource "aws_cloudfront_distribution" "live_streaming_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Live streaming distribution for ${var.project_name}"
  price_class         = var.cloudfront_price_class
  http_version        = "http2and3"

  # Placeholder origin - Update this after creating MediaPackage origin endpoints
  origin {
    domain_name = "${aws_media_package_channel.live_streaming_package.id}.egress.us-east-1.mediapackage.amazonaws.com"
    origin_id   = "mediapackage-placeholder"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Default cache behavior
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "mediapackage-placeholder"

    forwarded_values {
      query_string = true
      headers      = ["Origin", "Access-Control-Request-Method", "Access-Control-Request-Headers"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 5
    max_ttl                = 60
    compress               = true
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = var.cloudfront_minimum_protocol_version
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  dynamic "logging_config" {
    for_each = var.enable_cloudfront_logging ? [1] : []
    content {
      include_cookies = false
      bucket          = aws_s3_bucket.cloudfront_logs[0].bucket_domain_name
      prefix          = "cloudfront/"
    }
  }

  tags = {
    Name = "${local.resource_prefix}-distribution"
  }

  lifecycle {
    ignore_changes = [
      origin,
      default_cache_behavior
    ]
  }
}

# ==========================================
# CloudWatch Log Group for MediaLive
# ==========================================

resource "aws_cloudwatch_log_group" "medialive_log_group" {
  name              = "/aws/medialive/${local.resource_prefix}"
  retention_in_days = 7

  tags = {
    Name = "${local.resource_prefix}-medialive-logs"
  }
}