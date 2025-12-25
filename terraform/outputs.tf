output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket."
  value       = aws_s3_bucket.live_streaming_bucket.arn
}

output "medialive_channel_id" {
  description = "The ID of the MediaLive channel."
  value       = aws_medialive_channel.live_streaming_channel.id
}

output "mediapackage_channel_id" {
  description = "The ID of the MediaPackage channel."
  value       = aws_mediapackage_channel.live_streaming_package.id
}