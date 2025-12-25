# Live Streaming on AWS

How to implement Live streaming on AWS at scale leveraging AWS Elemental MediaLive, MediaPackage and Amazon CloudFront. This repo contains the source code for the AWS solution [Live Streaming on AWS](https://aws.amazon.com/solutions/implementations/live-streaming-on-aws/?did=sl_card&trk=sl_card).

## Architecture Overview

![Architecture](architecture.png)

**AWS Elemental MediaLive**<br/>
Is configured to ingest 2 live feeds and transcode the content into multiple adaptive bitrate HTTP live streaming (HLS) content.  The solution can be configured to ingest t Real-time Transport Protocol (RTP), Real-Time Messaging Protocol (RTMP), HTTP live streaming (HLS) and MediaConnect streams and will apply 1 of 3 encoding profiles which include bitrates of 1080p through 270p. The encoding profile is set at launch and is based on the source resolution (See Encoding Profiles below).

**AWS Elemental MediaPackage**<br/>
Ingests the MediaLive Output and package the Live stream into HTTP live streaming (HLS), Dynamic Adaptive Streaming over HTTP (DASH), and CMAF formats that are delivered through 3 MediaPackage custom endpoints.

**Amazon CloudFront**<br/>
Is configured with the MediaPackage custom endpoints as the Origins for the distribution. CloudFront then enable the live stream content to be delivered globally and at scale.

**Optional Demo Deployment**<br/>
As part of the Terraform configuration, a Demo HTML preview player can be deployed to an Amazon S3 bucket. This is a single-page HTML/JavaScript application that will playback the HTTP live streaming (HLS), Dynamic Adaptive Streaming over HTTP (DASH), MSS, and CMAF streams. Additionally, the solution can be configured to ingest a Demo HTTP live streaming (HLS) feed hosted on AWS.   


## Deployment
The solution is deployed using Terraform configuration files located in the `terraform/` directory.


## Encoding Profiles
To solution Configures AWS Elemental MediaLive with one of three encoding profiles based on the source resolution defined at launch as a Terraform variable. The three options are 1080, 720, 540 and correspond to the following encoding profiles:

* HD-1080p profile: 1920x1080, 1280x720, 960x540, 768x432, 640x360, 512x288
* HD-720p profile: 1280x720, 960x540, 768x432, 640x360, 512x288
* SD-540p profile:  960x540, 768x432, 640x360, 512x288

The profiles are defined in JSON and can be found in:
```
  source/custom-resource/lib/medialive/encoding-profiles/
```

## Source code

**source/custom-resources::**<br/>
A NodeJS-based Lambda function used as a custom resource for deploying MediaLive and MediaPackage resources through Terraform.

## Creating a custom build

### Prerequisites:
* [AWS Command Line Interface](https://aws.amazon.com/cli/)
* Node.js 12.x or later
* Terraform 1.0 or later

The solution is deployed using Terraform configuration files. Follow the steps below to create a custom build and deploy the solution:

### 1. Clone the repo
Download or clone the repo and make the required changes to the source code.

### 2. Running unit tests for customization
Run unit tests to make sure added customization passes the tests:
```
cd ./deployment
chmod +x ./run-unit-tests.sh && ./run-unit-tests.sh
```

### 3. Create an Amazon S3 Bucket
The Terraform configuration is set to pull the Lambda deployment packages from an Amazon S3 bucket in the region the solution is being launched in. Create a bucket in the desired region with the region name appended to the name of the bucket. eg: for us-east-1 create a bucket named: `my-bucket-us-east-1`
```
aws s3 mb s3://my-bucket-us-east-1
```

Ensure that you are the owner of the AWS S3 bucket. 
```
aws s3api head-bucket --bucket my-bucket-us-east-1 --expected-bucket-owner YOUR-AWS-ACCOUNT-NUMBER
```

### 4. Create the deployment packages
Build the distributable:
```
chmod +x ./build-s3-dist.sh
./build-s3-dist.sh <my-bucket> live-streaming-on-aws <version>
```

> **Notes**: The _build-s3-dist_ script expects the bucket name as one of its parameters. This value should not have the region suffix (remove the -us-east-1)

Deploy the distributable to the Amazon S3 bucket in your account:
```
aws s3 sync ./regional-s3-assets/ s3://my-bucket-us-east-1/live-streaming-on-aws/<version>/ 
aws s3 sync ./global-s3-assets/ s3://my-bucket-us-east-1/live-streaming-on-aws/<version>/ 
```

### 5. Deploy the solution with Terraform
1. Navigate to the `terraform/` directory:
   ```
   cd terraform
   ```

2. Initialize Terraform:
   ```
   terraform init
   ```

3. Plan the deployment:
   ```
   terraform plan
   ```

4. Apply the configuration:
   ```
   terraform apply
   ```

5. Destroy the resources when no longer needed:
   ```
   terraform destroy
   ```

## License

* This project is licensed under the terms of the Apache 2.0 license. See here `LICENSE`.

This solution collects anonymized operational metrics to help AWS improve the
quality of features of the solution. For more information, including how to disable
this capability, please see the [implementation guide](https://docs.aws.amazon.com/solutions/latest/live-streaming/welcome.html).