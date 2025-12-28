# Terraform Configuration for Live Streaming on AWS

This directory contains Terraform configuration files to deploy the Live Streaming on AWS solution. The following AWS resources are provisioned:

- S3 Bucket
- MediaLive Channel
- MediaPackage Channel

## Prerequisites

- Terraform installed on your machine.
- AWS CLI configured with appropriate credentials.

## Usage

1. Initialize Terraform:
   ```
   terraform init
   ```

2. Plan the deployment:
   ```
   terraform plan
   ```

3. Apply the configuration:
   ```
   terraform apply
   ```

4. Destroy the resources when no longer needed:
   ```
   terraform destroy
   ```

## Variables

- `aws_region`: The AWS region to deploy resources in (default: `eu-north-1`).
- `s3_bucket_name`: The name of the S3 bucket for live streaming.

## Outputs

- `s3_bucket_arn`: The ARN of the S3 bucket.
- `medialive_channel_id`: The ID of the MediaLive channel.
- `mediapackage_channel_id`: The ID of the MediaPackage channel.