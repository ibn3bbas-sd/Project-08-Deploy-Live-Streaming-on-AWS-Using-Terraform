provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "live_streaming_bucket" {
  bucket = var.s3_bucket_name
}

resource "aws_s3_bucket_acl" "live_streaming_bucket_acl" {
  bucket = aws_s3_bucket.live_streaming_bucket.id
  acl    = "private"
}

resource "aws_medialive_channel" "live_streaming_channel" {
  name          = "LiveStreamingChannel"
  channel_class = "STANDARD"

  destinations {
    media_package_settings {
      channel_id = aws_media_package_channel.live_streaming_package.id
    }
  }

  encoder_settings {
    # Define encoder settings here
  }

  input_attachments {
    input_id = "example-input-id"
  }

  input_specification {
    codec            = "AVC"
    resolution       = "HD"
    maximum_bitrate  = "MAX_10_MBPS"
  }
}

resource "aws_media_package_channel" "live_streaming_package" {
  id          = "example-channel-id"
  description = "Live streaming MediaPackage channel"
}
