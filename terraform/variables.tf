variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "eu-north-1"
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket for live streaming."
  type        = string
}