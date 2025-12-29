# outputs.tf

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.live_streaming_bucket.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.live_streaming_bucket.arn
}

output "mediapackage_channel_id" {
  description = "MediaPackage channel ID"
  value       = aws_media_package_channel.live_streaming_package.id
}

output "mediapackage_channel_arn" {
  description = "MediaPackage channel ARN"
  value       = aws_media_package_channel.live_streaming_package.arn
}

output "mediapackage_channel_ingest_endpoints" {
  description = "MediaPackage channel ingest endpoints"
  value = {
    username = aws_media_package_channel.live_streaming_package.hls_ingest[0].ingest_endpoints[0].username
    url_1    = aws_media_package_channel.live_streaming_package.hls_ingest[0].ingest_endpoints[0].url
    url_2    = length(aws_media_package_channel.live_streaming_package.hls_ingest[0].ingest_endpoints) > 1 ? aws_media_package_channel.live_streaming_package.hls_ingest[0].ingest_endpoints[1].url : null
  }
  sensitive = true
}

# MediaLive
output "medialive_channel_id" {
  description = "MediaLive channel ID"
  value       = aws_medialive_channel.live_streaming_channel.id
}

output "medialive_channel_arn" {
  description = "MediaLive channel ARN"
  value       = aws_medialive_channel.live_streaming_channel.arn
}

output "medialive_input_id" {
  description = "MediaLive input ID"
  value       = aws_medialive_input.live_streaming_input.id
}

output "medialive_input_destinations" {
  description = "MediaLive input destinations (RTMP push URLs)"
  value       = aws_medialive_input.live_streaming_input.destinations
  sensitive   = true
}

# CloudFront
output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.live_streaming_distribution.id
}

output "cloudfront_distribution_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.live_streaming_distribution.domain_name
}

output "cloudfront_distribution_url" {
  description = "CloudFront distribution URL"
  value       = "https://${aws_cloudfront_distribution.live_streaming_distribution.domain_name}"
}

# CloudWatch
output "medialive_log_group_name" {
  description = "MediaLive CloudWatch log group name"
  value       = aws_cloudwatch_log_group.medialive_log_group.name
}

output "medialive_log_group_arn" {
  description = "MediaLive CloudWatch log group ARN"
  value       = aws_cloudwatch_log_group.medialive_log_group.arn
}

# Instructions for creating origin endpoints
output "instructions" {
  description = "Instructions for completing the setup"
  value = <<-EOT
  
  ========================================
  IMPORTANT: Next Steps
  ========================================
  
  MediaPackage Origin Endpoints are not yet supported in the Terraform AWS provider.
  To complete your setup, you need to create them manually:
  
  Option 1: Use the provided script (recommended):
    chmod +x create_mediapackage_endpoints.sh
    ./create_mediapackage_endpoints.sh
  
  Option 2: Create manually via AWS Console:
    1. Go to AWS MediaPackage Console
    2. Select your channel: ${aws_media_package_channel.live_streaming_package.id}
    3. Create origin endpoints for HLS, DASH, and/or CMAF
    4. Update CloudFront origins with the endpoint URLs
  
  Option 3: Use AWS CLI:
    aws mediapackage create-origin-endpoint \\
      --channel-id ${aws_media_package_channel.live_streaming_package.id} \\
      --id ${aws_media_package_channel.live_streaming_package.id}-hls \\
      --hls-package SegmentDurationSeconds=6,PlaylistWindowSeconds=60
  
  After creating endpoints, update CloudFront distribution origins.
  
  EOT
}