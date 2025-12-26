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

# HLS Endpoint
resource "aws_media_package_origin_endpoint" "hls_endpoint" {
  count               = var.enable_hls ? 1 : 0
  channel_id          = aws_media_package_channel.live_streaming_package.id
  endpoint_id         = "${local.resource_prefix}-hls-${local.unique_id}"
  description         = "HLS endpoint for live streaming"
  manifest_name       = "index"
  startover_window_seconds = var.startover_window_seconds

  hls_package {
    segment_duration_seconds = var.mediapackage_segment_duration
    playlist_window_seconds  = var.mediapackage_manifest_window
    playlist_type            = "EVENT"
    ad_markers               = "NONE"
    include_iframe_only_stream = false
    program_date_time_interval_seconds = 60

    stream_selection {
      stream_order = "ORIGINAL"
    }
  }

  dynamic "authorization" {
    for_each = var.enable_cdn_authorization ? [1] : []
    content {
      cdn_identifier_secret = aws_secretsmanager_secret.cdn_secret[0].arn
      secrets_role_arn      = aws_iam_role.mediapackage_secrets_role[0].arn
    }
  }
}

# DASH Endpoint
resource "aws_media_package_origin_endpoint" "dash_endpoint" {
  count               = var.enable_dash ? 1 : 0
  channel_id          = aws_media_package_channel.live_streaming_package.id
  endpoint_id         = "${local.resource_prefix}-dash-${local.unique_id}"
  description         = "DASH endpoint for live streaming"
  manifest_name       = "index"
  startover_window_seconds = var.startover_window_seconds

  dash_package {
    segment_duration_seconds = var.mediapackage_segment_duration
    manifest_window_seconds  = var.mediapackage_manifest_window
    profile                  = "NONE"
    
    stream_selection {
      stream_order = "ORIGINAL"
    }
  }

  dynamic "authorization" {
    for_each = var.enable_cdn_authorization ? [1] : []
    content {
      cdn_identifier_secret = aws_secretsmanager_secret.cdn_secret[0].arn
      secrets_role_arn      = aws_iam_role.mediapackage_secrets_role[0].arn
    }
  }
}

# CMAF Endpoint
resource "aws_media_package_origin_endpoint" "cmaf_endpoint" {
  count               = var.enable_cmaf ? 1 : 0
  channel_id          = aws_media_package_channel.live_streaming_package.id
  endpoint_id         = "${local.resource_prefix}-cmaf-${local.unique_id}"
  description         = "CMAF endpoint for live streaming"
  manifest_name       = "index"
  startover_window_seconds = var.startover_window_seconds

  cmaf_package {
    segment_duration_seconds = var.mediapackage_segment_duration
    
    hls_manifests {
      manifest_name        = "index"
      playlist_window_seconds = var.mediapackage_manifest_window
      program_date_time_interval_seconds = 60
    }

    stream_selection {
      stream_order = "ORIGINAL"
    }
  }

  dynamic "authorization" {
    for_each = var.enable_cdn_authorization ? [1] : []
    content {
      cdn_identifier_secret = aws_secretsmanager_secret.cdn_secret[0].arn
      secrets_role_arn      = aws_iam_role.mediapackage_secrets_role[0].arn
    }
  }
}

# MSS Endpoint
resource "aws_media_package_origin_endpoint" "mss_endpoint" {
  count               = var.enable_mss ? 1 : 0
  channel_id          = aws_media_package_channel.live_streaming_package.id
  endpoint_id         = "${local.resource_prefix}-mss-${local.unique_id}"
  description         = "MSS endpoint for live streaming"
  manifest_name       = "index"
  startover_window_seconds = var.startover_window_seconds

  mss_package {
    segment_duration_seconds = var.mediapackage_segment_duration
    manifest_window_seconds  = var.mediapackage_manifest_window
    
    stream_selection {
      stream_order = "ORIGINAL"
    }
  }

  dynamic "authorization" {
    for_each = var.enable_cdn_authorization ? [1] : []
    content {
      cdn_identifier_secret = aws_secretsmanager_secret.cdn_secret[0].arn
      secrets_role_arn      = aws_iam_role.mediapackage_secrets_role[0].arn
    }
  }
}

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

  dynamic "sources" {
    for_each = var.channel_class == "STANDARD" ? [1, 2] : [1]
    content {
      password_param = ""
      url            = ""
      username       = ""
    }
  }

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
    resolution       = var.encoding_profile == "1080" ? "HD" : (var.encoding_profile == "720" ? "HD" : "SD")
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
          rate_control    = "CBR"
          raw_format      = "NONE"
          sample_rate     = 48000
          spec            = "MPEG4"
        }
      }
    }

    # Video descriptions for each resolution in the encoding profile
    dynamic "video_descriptions" {
      for_each = toset(local.encoding_profiles[var.encoding_profile])
      content {
        name              = "video_${replace(video_descriptions.value, "x", "_")}"
        respond_to_afd    = "NONE"
        scaling_behavior  = "DEFAULT"
        sharpness         = 50

        codec_settings {
          h264_settings {
            adaptive_quantization = "HIGH"
            afd_signaling        = "NONE"
            bitrate              = tonumber(split("x", video_descriptions.value)[0]) * 3
            color_metadata       = "INSERT"
            entropy_encoding     = "CABAC"
            flicker_aq          = "ENABLED"
            framerate_control   = "SPECIFIED"
            framerate_numerator = 30000
            framerate_denominator = 1001
            gop_b_reference     = "DISABLED"
            gop_closed_cadence  = 1
            gop_num_b_frames    = 3
            gop_size            = 60
            gop_size_units      = "FRAMES"
            level               = "H264_LEVEL_AUTO"
            look_ahead_rate_control = "HIGH"
            num_ref_frames      = 3
            par_control         = "SPECIFIED"
            profile             = "HIGH"
            rate_control_mode   = "CBR"
            scan_type           = "PROGRESSIVE"
            scene_change_detect = "ENABLED"
            spatial_aq          = "ENABLED"
            syntax              = "DEFAULT"
            temporal_aq         = "ENABLED"
            timecode_insertion  = "DISABLED"
          }
        }

        height = tonumber(split("x", video_descriptions.value)[1])
        width  = tonumber(split("x", video_descriptions.value)[0])
      }
    }

    output_groups {
      output_group_settings {
        media_package_group_settings {
          destination {
            destination_ref_id = "mediapackage-destination"
          }
        }
      }

      dynamic "outputs" {
        for_each = toset(local.encoding_profiles[var.encoding_profile])
        content {
          output_name             = replace(outputs.value, "x", "_")
          video_description_name  = "video_${replace(outputs.value, "x", "_")}"
          audio_description_names = ["audio_1"]
          output_settings {
            media_package_output_settings {}
          }
        }
      }
    }
  }

  input_attachments {
    input_id                = aws_medialive_input.live_streaming_input.id
    input_attachment_name   = "input-attachment"
  }

  tags = {
    Name = "${local.resource_prefix}-channel"
  }
}

# ==========================================
# CloudFront Distribution
# ==========================================

resource "aws_cloudfront_distribution" "live_streaming_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Live streaming distribution for ${var.project_name}"
  price_class         = var.cloudfront_price_class
  http_version        = "http2and3"

  # HLS Origin
  dynamic "origin" {
    for_each = var.enable_hls ? [1] : []
    content {
      domain_name = replace(aws_media_package_origin_endpoint.hls_endpoint[0].url, "https://", "")
      origin_id   = "mediapackage-hls"
      origin_path = ""

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  # DASH Origin
  dynamic "origin" {
    for_each = var.enable_dash ? [1] : []
    content {
      domain_name = replace(aws_media_package_origin_endpoint.dash_endpoint[0].url, "https://", "")
      origin_id   = "mediapackage-dash"
      origin_path = ""

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  # CMAF Origin
  dynamic "origin" {
    for_each = var.enable_cmaf ? [1] : []
    content {
      domain_name = replace(aws_media_package_origin_endpoint.cmaf_endpoint[0].url, "https://", "")
      origin_id   = "mediapackage-cmaf"
      origin_path = ""

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  # Default cache behavior (HLS)
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.enable_hls ? "mediapackage-hls" : (var.enable_dash ? "mediapackage-dash" : "mediapackage-cmaf")

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

  # Additional cache behaviors for DASH and CMAF
  dynamic "ordered_cache_behavior" {
    for_each = var.enable_dash ? [1] : []
    content {
      path_pattern     = "/out/v1/*/index.mpd*"
      allowed_methods  = ["GET", "HEAD", "OPTIONS"]
      cached_methods   = ["GET", "HEAD"]
      target_origin_id = "mediapackage-dash"

      forwarded_values {
        query_string = true
        headers      = ["Origin"]

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