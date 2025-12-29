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

# HLS Endpoint
output "mediapackage_hls_endpoint_url" {
  description = "MediaPackage HLS endpoint URL"
  value       = var.enable_hls ? awscc_mediapackage_origin_endpoint.hls_endpoint[0].url : null
}

output "mediapackage_hls_endpoint_id" {
  description = "MediaPackage HLS endpoint ID"
  value       = var.enable_hls ? awscc_mediapackage_origin_endpoint.hls_endpoint[0].id : null
}

# DASH Endpoint
output "mediapackage_dash_endpoint_url" {
  description = "MediaPackage DASH endpoint URL"
  value       = var.enable_dash ? awscc_mediapackage_origin_endpoint.dash_endpoint[0].url : null
}

output "mediapackage_dash_endpoint_id" {
  description = "MediaPackage DASH endpoint ID"
  value       = var.enable_dash ? awscc_mediapackage_origin_endpoint.dash_endpoint[0].id : null
}

# CMAF Endpoint
output "mediapackage_cmaf_endpoint_url" {
  description = "MediaPackage CMAF endpoint URL"
  value       = var.enable_cmaf ? awscc_mediapackage_origin_endpoint.cmaf_endpoint[0].url : null
}

output "mediapackage_cmaf_endpoint_id" {
  description = "MediaPackage CMAF endpoint ID"
  value       = var.enable_cmaf ? awscc_mediapackage_origin_endpoint.cmaf_endpoint[0].id : null
}

# MSS Endpoint
output "mediapackage_mss_endpoint_url" {
  description = "MediaPackage MSS endpoint URL"
  value       = var.enable_mss ? awscc_mediapackage_origin_endpoint.mss_endpoint[0].url : null
}

output "mediapackage_mss_endpoint_id" {
  description = "MediaPackage MSS endpoint ID"
  value       = var.enable_mss ? awscc_mediapackage_origin_endpoint.mss_endpoint[0].id : null
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
  description = "MediaLive input destinations"
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