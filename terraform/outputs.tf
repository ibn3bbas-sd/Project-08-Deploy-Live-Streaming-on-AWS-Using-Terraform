# outputs.tf

# ==========================================
# S3 Bucket Outputs
# ==========================================

output "s3_bucket_name" {
  description = "The name of the S3 bucket for live streaming"
  value       = aws_s3_bucket.live_streaming_bucket.id
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.live_streaming_bucket.arn
}

output "s3_bucket_region" {
  description = "The region of the S3 bucket"
  value       = aws_s3_bucket.live_streaming_bucket.region
}

# ==========================================
# MediaLive Outputs
# ==========================================

output "medialive_channel_id" {
  description = "The ID of the MediaLive channel"
  value       = aws_medialive_channel.live_streaming_channel.id
}

output "medialive_channel_arn" {
  description = "The ARN of the MediaLive channel"
  value       = aws_medialive_channel.live_streaming_channel.arn
}

output "medialive_input_id" {
  description = "The ID of the MediaLive input"
  value       = aws_medialive_input.live_streaming_input.id
}

output "medialive_input_endpoints" {
  description = "MediaLive input endpoints for streaming"
  value       = var.input_type == "RTMP_PUSH" ? [for dest in aws_medialive_input.live_streaming_input.destinations : "rtmp://${dest.ip}:1935/${dest.stream_name}"] : []
  sensitive   = false
}

output "medialive_input_security_group" {
  description = "MediaLive input security group ID"
  value       = var.input_type == "RTMP_PUSH" || var.input_type == "RTP_PUSH" ? aws_medialive_input_security_group.live_streaming_sg[0].id : null
}

# ==========================================
# MediaPackage Outputs
# ==========================================

output "mediapackage_channel_id" {
  description = "The ID of the MediaPackage channel"
  value       = aws_media_package_channel.live_streaming_package.id
}

output "mediapackage_channel_arn" {
  description = "The ARN of the MediaPackage channel"
  value       = aws_media_package_channel.live_streaming_package.arn
}

output "mediapackage_hls_endpoint_url" {
  description = "MediaPackage HLS endpoint URL"
  value       = var.enable_hls ? aws_media_package_origin_endpoint.hls_endpoint[0].url : null
}

output "mediapackage_dash_endpoint_url" {
  description = "MediaPackage DASH endpoint URL"
  value       = var.enable_dash ? aws_media_package_origin_endpoint.dash_endpoint[0].url : null
}

output "mediapackage_cmaf_endpoint_url" {
  description = "MediaPackage CMAF endpoint URL"
  value       = var.enable_cmaf ? aws_media_package_origin_endpoint.cmaf_endpoint[0].url : null
}

output "mediapackage_mss_endpoint_url" {
  description = "MediaPackage MSS endpoint URL"
  value       = var.enable_mss ? aws_media_package_origin_endpoint.mss_endpoint[0].url : null
}

# ==========================================
# CloudFront Outputs
# ==========================================

output "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.live_streaming_distribution.id
}

output "cloudfront_distribution_arn" {
  description = "The ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.live_streaming_distribution.arn
}

output "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.live_streaming_distribution.domain_name
}

output "cloudfront_hls_url" {
  description = "CloudFront HLS playback URL"
  value       = var.enable_hls ? "https://${aws_cloudfront_distribution.live_streaming_distribution.domain_name}${replace(aws_media_package_origin_endpoint.hls_endpoint[0].url, "https://${replace(aws_media_package_origin_endpoint.hls_endpoint[0].url, "https://", "")}", "")}/index.m3u8" : null
}

output "cloudfront_dash_url" {
  description = "CloudFront DASH playback URL"
  value       = var.enable_dash ? "https://${aws_cloudfront_distribution.live_streaming_distribution.domain_name}${replace(aws_media_package_origin_endpoint.dash_endpoint[0].url, "https://${replace(aws_media_package_origin_endpoint.dash_endpoint[0].url, "https://", "")}", "")}/index.mpd" : null
}

# ==========================================
# IAM Role Outputs
# ==========================================

output "medialive_role_arn" {
  description = "The ARN of the MediaLive IAM role"
  value       = aws_iam_role.medialive_role.arn
}

# ==========================================
# Configuration Summary
# ==========================================

output "configuration_summary" {
  description = "Summary of the live streaming configuration"
  value = {
    project_name      = var.project_name
    environment       = var.environment
    region            = var.aws_region
    encoding_profile  = var.encoding_profile
    input_type        = var.input_type
    channel_class     = var.channel_class
    enabled_formats   = {
      hls  = var.enable_hls
      dash = var.enable_dash
      cmaf = var.enable_cmaf
      mss  = var.enable_mss
    }
  }
}

# ==========================================
# Quick Start Guide
# ==========================================

output "quick_start_guide" {
  description = "Quick start instructions for using the live streaming solution"
  value = <<-EOT
    ╔════════════════════════════════════════════════════════════════════════════╗
    ║                    Live Streaming on AWS - Quick Start                     ║
    ╚════════════════════════════════════════════════════════════════════════════╝
    
    1. Start the MediaLive Channel:
       aws medialive start-channel --channel-id ${aws_medialive_channel.live_streaming_channel.id}
    
    2. Stream to MediaLive Input:
       ${var.input_type == "RTMP_PUSH" ? "RTMP Endpoints:\n       ${join("\n       ", [for dest in aws_medialive_input.live_streaming_input.destinations : "rtmp://${dest.ip}:1935/${dest.stream_name}"])}" : "Configure your input source in the MediaLive console"}
    
    3. Access Your Stream:
       ${var.enable_hls ? "HLS:  https://${aws_cloudfront_distribution.live_streaming_distribution.domain_name}/out/v1/${aws_media_package_origin_endpoint.hls_endpoint[0].id}/index.m3u8" : ""}
       ${var.enable_dash ? "DASH: https://${aws_cloudfront_distribution.live_streaming_distribution.domain_name}/out/v1/${aws_media_package_origin_endpoint.dash_endpoint[0].id}/index.mpd" : ""}
    
    4. Monitor Your Stream:
       - CloudWatch Logs: /aws/medialive/${local.resource_prefix}
       - MediaLive Console: https://console.aws.amazon.com/medialive/
       - CloudFront Metrics: https://console.aws.amazon.com/cloudfront/
    
    5. Stop the Channel (to avoid charges):
       aws medialive stop-channel --channel-id ${aws_medialive_channel.live_streaming_channel.id}
    
    ═══════════════════════════════════════════════════════════════════════════════
    📖 Documentation: https://docs.aws.amazon.com/solutions/latest/live-streaming/
    💰 Cost Estimate: ~$200-400/month for 24/7 HD streaming
    🔒 Security: All endpoints use HTTPS by default
    ═══════════════════════════════════════════════════════════════════════════════
  EOT
}

# ==========================================
# Demo Player Information
# ==========================================

output "demo_player_info" {
  description = "Information about the demo player (if enabled)"
  value = var.enable_demo ? {
    s3_bucket        = aws_s3_bucket.live_streaming_bucket.id
    demo_player_path = "demo-player/index.html"
    note             = "Upload demo player HTML to the S3 bucket to test playback"
  } : null
}

# ==========================================
# Cost Optimization Tips
# ==========================================

output "cost_optimization_tips" {
  description = "Tips for optimizing costs"
  value = <<-EOT
    💰 Cost Optimization Tips:
    
    1. Stop MediaLive channels when not streaming (charges apply when running)
    2. Use SINGLE_PIPELINE for non-critical streams to reduce costs by 50%
    3. Choose appropriate encoding profile (540p is cheaper than 1080p)
    4. Configure CloudFront price class based on your audience geography
    5. Set appropriate MediaPackage retention policies
    6. Enable CloudFront compression to reduce data transfer costs
    7. Monitor usage with AWS Cost Explorer
    
    Current Configuration:
    - Channel Class: ${var.channel_class} ${var.channel_class == "SINGLE_PIPELINE" ? "✓ Cost-optimized" : "⚠ Higher cost for redundancy"}
    - Encoding Profile: ${var.encoding_profile}p ${var.encoding_profile == "540" ? "✓ Cost-optimized" : ""}
    - CloudFront Price Class: ${var.cloudfront_price_class}
  EOT
}

# ==========================================
# Troubleshooting Information
# ==========================================

output "troubleshooting_info" {
  description = "Common troubleshooting commands and resources"
  value = <<-EOT
    🔧 Troubleshooting Commands:
    
    # Check MediaLive channel status
    aws medialive describe-channel --channel-id ${aws_medialive_channel.live_streaming_channel.id}
    
    # View MediaLive logs
    aws logs tail /aws/medialive/${local.resource_prefix} --follow
    
    # Check MediaPackage channel status
    aws mediapackage describe-channel --id ${aws_media_package_channel.live_streaming_package.id}
    
    # Test stream endpoints
    curl -I ${var.enable_hls ? aws_media_package_origin_endpoint.hls_endpoint[0].url : "N/A"}
    
    # View CloudFront cache statistics
    aws cloudfront get-distribution --id ${aws_cloudfront_distribution.live_streaming_distribution.id}
    
    Common Issues:
    - Channel won't start: Check input source is accessible and sending data
    - Playback buffering: Verify encoding profile matches source resolution
    - 403 errors: Check MediaPackage endpoint permissions and CDN authorization
    - High latency: Review segment duration and manifest window settings
  EOT
}