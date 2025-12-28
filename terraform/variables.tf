# variables.tf

variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "eu-north-1"
}

variable "project_name" {
  description = "Project name used as prefix for resource names"
  type        = string
  default     = "live-streaming"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket for live streaming artifacts and demo player"
  type        = string
}

variable "encoding_profile" {
  description = "Encoding profile based on source resolution (1080, 720, or 540)"
  type        = string
  default     = "720"
  
  validation {
    condition     = contains(["1080", "720", "540"], var.encoding_profile)
    error_message = "Encoding profile must be one of: 1080, 720, or 540"
  }
}

variable "input_type" {
  description = "Type of input stream (RTMP_PUSH, RTMP_PULL, RTP_PUSH, HLS_PULL, MEDIACONNECT)"
  type        = string
  default     = "RTMP_PUSH"
  
  validation {
    condition     = contains(["RTMP_PUSH", "RTMP_PULL", "RTP_PUSH", "HLS_PULL", "MEDIACONNECT"], var.input_type)
    error_message = "Input type must be one of: RTMP_PUSH, RTMP_PULL, RTP_PUSH, HLS_PULL, or MEDIACONNECT"
  }
}

variable "input_codec" {
  description = "Input codec (AVC or HEVC)"
  type        = string
  default     = "AVC"
  
  validation {
    condition     = contains(["AVC", "HEVC"], var.input_codec)
    error_message = "Input codec must be either AVC or HEVC"
  }
}

variable "channel_class" {
  description = "MediaLive channel class (STANDARD or SINGLE_PIPELINE)"
  type        = string
  default     = "STANDARD"
  
  validation {
    condition     = contains(["STANDARD", "SINGLE_PIPELINE"], var.channel_class)
    error_message = "Channel class must be either STANDARD or SINGLE_PIPELINE"
  }
}

variable "enable_hls" {
  description = "Enable HLS output endpoint"
  type        = bool
  default     = true
}

variable "enable_dash" {
  description = "Enable DASH output endpoint"
  type        = bool
  default     = true
}

variable "enable_cmaf" {
  description = "Enable CMAF output endpoint"
  type        = bool
  default     = true
}

variable "enable_mss" {
  description = "Enable Microsoft Smooth Streaming output endpoint"
  type        = bool
  default     = false
}

variable "enable_demo" {
  description = "Deploy demo HTML preview player to S3"
  type        = bool
  default     = false
}

variable "cloudfront_price_class" {
  description = "CloudFront distribution price class"
  type        = string
  default     = "PriceClass_100"
  
  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.cloudfront_price_class)
    error_message = "Price class must be one of: PriceClass_100, PriceClass_200, or PriceClass_All"
  }
}

variable "cloudfront_minimum_protocol_version" {
  description = "Minimum TLS protocol version for CloudFront"
  type        = string
  default     = "TLSv1.2_2021"
}

variable "enable_cloudfront_logging" {
  description = "Enable CloudFront access logging"
  type        = bool
  default     = false
}

variable "mediapackage_segment_duration" {
  description = "Duration of each segment in seconds"
  type        = number
  default     = 6
}

variable "mediapackage_manifest_window" {
  description = "Time window for manifest in seconds"
  type        = number
  default     = 60
}

variable "enable_metrics" {
  description = "Enable anonymized operational metrics collection"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "artifact_bucket" {
  description = "S3 bucket containing Lambda deployment packages"
  type        = string
  default     = ""
}

variable "solution_version" {
  description = "Solution version for Lambda artifacts"
  type        = string
  default     = "v1.0.0"
}

variable "input_security_group_whitelist" {
  description = "CIDR blocks to whitelist for MediaLive input security group"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "startover_window_seconds" {
  description = "Size of the startover window in seconds (0 to disable)"
  type        = number
  default     = 0
}

variable "enable_cdn_authorization" {
  description = "Enable CDN authorization for MediaPackage endpoints"
  type        = bool
  default     = false
}