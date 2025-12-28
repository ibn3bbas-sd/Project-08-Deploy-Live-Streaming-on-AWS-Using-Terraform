# Deploy Live Streaming on AWS Using Terraform

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.0-623CE4)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-MediaServices-FF9900)](https://aws.amazon.com/)

A production-ready infrastructure-as-code solution for deploying scalable live streaming on AWS. This implementation leverages AWS Elemental MediaLive, MediaPackage, and Amazon CloudFront to deliver adaptive bitrate streaming content globally.

This repository contains the source code for the AWS solution [Live Streaming on AWS](https://aws.amazon.com/solutions/implementations/live-streaming-on-aws/?did=sl_card&trk=sl_card).

## 📋 Table of Contents

- [Features](#features)
- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Encoding Profiles](#encoding-profiles)
- [Deployment Guide](#deployment-guide)
- [Configuration Options](#configuration-options)
- [Monitoring and Troubleshooting](#monitoring-and-troubleshooting)
- [Custom Build Instructions](#creating-a-custom-build)
- [Cost Considerations](#cost-considerations)
- [Contributing](#contributing)
- [License](#license)

## ✨ Features

- **Multi-format streaming**: Supports:
   HTTP Live Streaming (HLS)
   Dynamic Adaptive Streaming over HTTP (DASH)
   Common Media Application Format (CMAF)
   Microsoft Smooth Streaming (MSS)
- **Adaptive bitrate encoding**: Automatic transcoding to multiple resolutions (1080p to 270p)
- **Global content delivery**: CloudFront integration for low-latency worldwide distribution
- **Flexible input sources**: Supports RTP, RTMP, HLS, and MediaConnect streams
- **High availability**: Dual-pipeline architecture with automatic failover
- **Infrastructure as Code**: Fully automated deployment using Terraform
- **Demo player included**: Optional HTML5 preview player for testing
- **Production-ready**: Battle-tested architecture from AWS Solutions Library

## 🏗️ Architecture Overview

![Architecture](architecture.png)

### Components

#### AWS Elemental MediaLive
Ingests two live feeds for redundancy and transcodes content into multiple adaptive bitrate HLS streams. The solution supports various input protocols:
- Real-Time Transport Protocol (RTP)
- Real-Time Messaging Protocol (RTMP)
- HTTP Live Streaming (HLS)
- AWS MediaConnect streams

MediaLive applies one of three encoding profiles based on your source resolution, generating multiple renditions from 1080p down to 270p for optimal viewing across devices and network conditions.

#### AWS Elemental MediaPackage
Ingests the MediaLive output and packages the live stream into multiple formats:
- HTTP Live Streaming (HLS)
- Dynamic Adaptive Streaming over HTTP (DASH)
- Common Media Application Format (CMAF)

Three MediaPackage custom endpoints are created to deliver these formats independently.

#### Amazon CloudFront
Configured with MediaPackage endpoints as origins, CloudFront delivers your live stream content globally with:
- Low latency through edge locations worldwide
- Automatic scaling to handle traffic spikes
- Built-in DDoS protection
- HTTPS support for secure streaming

#### Optional Demo Deployment
A single-page HTML/JavaScript application can be deployed to Amazon S3 for testing and demonstration purposes. This player supports playback of all streaming formats and can be configured to ingest a demo HLS feed hosted on AWS.

## 📦 Prerequisites

Before deploying this solution, ensure you have:

- **AWS Account**: With appropriate permissions to create MediaLive, MediaPackage, CloudFront, S3, and Lambda resources
- **AWS CLI**: Version 2.x or later ([installation guide](https://aws.amazon.com/cli/))
- **Terraform**: Version 1.0 or later ([installation guide](https://www.terraform.io/downloads))
- **Node.js**: Version 12.x or later for building Lambda functions
- **Git**: For cloning the repository
- **Basic knowledge**: Familiarity with AWS services and streaming concepts

### IAM Permissions Required

Your AWS user or role needs permissions for:
- MediaLive (create/configure channels and inputs)
- MediaPackage (create channels and endpoints)
- CloudFront (create distributions)
- S3 (create buckets, upload objects)
- Lambda (create functions, manage roles)
- IAM (create roles and policies)
- CloudFormation (if using custom resources)

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/ibn3bbas-sd/Project-08-Deploy-Live-Streaming-on-AWS-Using-Terraform.git
cd Project-08-Deploy-Live-Streaming-on-AWS-Using-Terraform

# Navigate to Terraform directory
cd terraform

# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Deploy the solution
terraform apply

# When finished, destroy resources
terraform destroy
```

## 📊 Encoding Profiles

The solution configures AWS Elemental MediaLive with one of three encoding profiles based on your source resolution. Select the appropriate profile using the Terraform variable at launch:

### HD-1080p Profile (1080)
Optimized for full HD sources:
- 1920x1080 @ 5000 kbps
- 1280x720 @ 3000 kbps
- 960x540 @ 2000 kbps
- 768x432 @ 1200 kbps
- 640x360 @ 800 kbps
- 512x288 @ 400 kbps

### HD-720p Profile (720)
Optimized for HD sources:
- 1280x720 @ 3000 kbps
- 960x540 @ 2000 kbps
- 768x432 @ 1200 kbps
- 640x360 @ 800 kbps
- 512x288 @ 400 kbps

### SD-540p Profile (540)
Optimized for standard definition sources:
- 960x540 @ 2000 kbps
- 768x432 @ 1200 kbps
- 640x360 @ 800 kbps
- 512x288 @ 400 kbps

Profile definitions are located in:
```
source/custom-resource/lib/medialive/encoding-profiles/
```

## 📖 Deployment Guide

### Standard Deployment

1. **Configure AWS credentials**:
   ```bash
   aws configure
   ```

2. **Navigate to the Terraform directory**:
   ```bash
   cd terraform
   ```

3. **Create a `terraform.tfvars` file** with your configuration:
   ```hcl
   region              = "us-east-1"
   encoding_profile    = "1080"
   enable_demo         = true
   project_name        = "my-live-stream"
   ```

4. **Initialize and deploy**:
   ```bash
   terraform init
   terraform plan -out=tfplan
   terraform apply tfplan
   ```

5. **Retrieve outputs**:
   ```bash
   terraform output
   ```

### Configuration Parameters

Key Terraform variables you can customize:

- `region`: AWS region for deployment
- `encoding_profile`: Choose from "1080", "720", or "540"
- `enable_demo`: Deploy demo player (true/false)
- `input_type`: Stream input type (RTP, RTMP, HLS, MediaConnect)
- `project_name`: Prefix for resource names
- `cloudfront_price_class`: CloudFront distribution price class

Refer to `terraform/variables.tf` for complete configuration options.

## 🔧 Configuration Options

### Input Configuration

Configure your streaming source by setting the appropriate variables:

```hcl
input_type     = "RTMP_PUSH"
input_codec    = "AVC"
stream_name    = "my-stream"
```

### Output Configuration

Customize output formats and endpoints:

```hcl
enable_hls     = true
enable_dash    = true
enable_cmaf    = true
```

### Security Configuration

Enable additional security features:

```hcl
enable_cloudfront_authentication = true
enable_mediapackage_authorization = true
```

## 📈 Monitoring and Troubleshooting

### CloudWatch Metrics

The solution automatically publishes metrics to CloudWatch:
- MediaLive channel health
- MediaPackage ingress/egress data
- CloudFront request counts and error rates

### Logs

Access logs in CloudWatch Logs:
- `/aws/lambda/custom-resource`: Custom resource execution logs
- MediaLive logs: Available in MediaLive console
- CloudFront logs: Can be enabled to S3

### Common Issues

**Issue**: MediaLive channel fails to start
- **Solution**: Verify input source is accessible and sending data

**Issue**: Playback stuttering or buffering
- **Solution**: Check encoding profile matches source resolution

**Issue**: CloudFront 403 errors
- **Solution**: Verify MediaPackage endpoint permissions

## 🛠️ Creating a Custom Build

### Step 1: Clone and Modify

```bash
git clone https://github.com/awslabs/live-streaming-on-aws.git
cd live-streaming-on-aws
# Make your modifications to the source code
```

### Step 2: Run Unit Tests

```bash
cd deployment
chmod +x ./run-unit-tests.sh
./run-unit-tests.sh
```

### Step 3: Create S3 Bucket

Create a regional bucket for deployment artifacts:

```bash
export AWS_REGION=us-east-1
export BUCKET_NAME=my-live-streaming-bucket

aws s3 mb s3://${BUCKET_NAME}-${AWS_REGION} --region ${AWS_REGION}

# Verify bucket ownership
aws s3api head-bucket \
  --bucket ${BUCKET_NAME}-${AWS_REGION} \
  --expected-bucket-owner $(aws sts get-caller-identity --query Account --output text)
```

### Step 4: Build Deployment Packages

```bash
cd deployment
chmod +x ./build-s3-dist.sh
./build-s3-dist.sh ${BUCKET_NAME} live-streaming-on-aws v1.0.0
```

**Note**: The bucket name parameter should not include the region suffix.

### Step 5: Upload to S3

```bash
aws s3 sync ./regional-s3-assets/ s3://${BUCKET_NAME}-${AWS_REGION}/live-streaming-on-aws/v1.0.0/
aws s3 sync ./global-s3-assets/ s3://${BUCKET_NAME}-${AWS_REGION}/live-streaming-on-aws/v1.0.0/
```

### Step 6: Deploy Custom Build

```bash
cd ../terraform
terraform init
terraform apply \
  -var="artifact_bucket=${BUCKET_NAME}-${AWS_REGION}" \
  -var="solution_version=v1.0.0"
```

## 💰 Cost Considerations

This solution incurs AWS service charges. Primary cost drivers include:

- **MediaLive**: Charges based on input type and encoding profile (~$2.40-$4.80/hour for standard channels)
- **MediaPackage**: Ingress and egress data transfer charges
- **CloudFront**: Data transfer and request charges
- **S3**: Storage and request charges (minimal)
- **Lambda**: Execution charges (minimal)

**Estimate**: A typical 24/7 HD stream costs approximately $200-400/month, varying by region, encoding profile, and viewer traffic.

Use the [AWS Pricing Calculator](https://calculator.aws/) for detailed estimates based on your specific requirements.

## 📂 Repository Structure

```
.
├── deployment/                 # Build and deployment scripts
│   ├── build-s3-dist.sh
│   └── run-unit-tests.sh
├── source/
│   ├── console/                # React frontend for the demo player
│   │   ├── public/index.html
│   │   └── src/App.js
│   ├── constructs/             # AWS CDK constructs for infrastructure
│   │   ├── bin/live-streaming.ts
│   │   ├── lib/live-streaming.ts
│   │   └── test/live-streaming.test.ts
│   └── custom-resource/        # Lambda functions for custom resources
│       ├── lib/
│       │   ├── medialive/
│       │   └── mediapackage/
│       └── index.js
├── terraform/                  # Terraform configuration for AWS resources
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── .gitignore
├── architecture.png
├── LICENSE.txt
└── README.md
```

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure all tests pass and follow the existing code style.

## 📄 License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.

## 🔒 Privacy and Data Collection

This solution collects anonymized operational metrics to help AWS improve solution quality. These metrics include:

- Solution ID and version
- Deployment timestamp
- AWS region
- Encoding profile selected

**To disable metrics collection**, see the [implementation guide](https://docs.aws.amazon.com/solutions/latest/live-streaming/welcome.html).

No personal information or streaming content is collected.

## 📚 Additional Resources

- [AWS Elemental MediaLive Documentation](https://docs.aws.amazon.com/medialive/)
- [AWS Elemental MediaPackage Documentation](https://docs.aws.amazon.com/mediapackage/)
- [Amazon CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)
- [Live Streaming on AWS Implementation Guide](https://docs.aws.amazon.com/solutions/latest/live-streaming/)
- [AWS Media Services](https://aws.amazon.com/media-services/)

## 💬 Support

For issues, questions, or feature requests:

- Open an issue in this repository
- Consult the [implementation guide](https://docs.aws.amazon.com/solutions/latest/live-streaming/)
- Contact AWS Support (if you have a support plan)

---

**Note**: Ensure you properly stop or delete MediaLive channels when not in use to avoid unnecessary charges, as MediaLive charges based on channel runtime regardless of whether content is being streamed.