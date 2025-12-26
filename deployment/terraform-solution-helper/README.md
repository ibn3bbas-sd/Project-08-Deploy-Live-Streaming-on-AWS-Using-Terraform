# terraform-solution-helper

A lightweight helper utility that prepares Terraform configurations and Lambda deployment packages for the AWS Solutions publishing pipeline. This tool performs the following tasks:

## Features

### 🔧 Terraform Configuration Preparation

Replaces hardcoded values in Terraform configurations with standardized placeholders used by the AWS Solutions publishing pipeline:

- **S3 Bucket references** are replaced with `%%BUCKET_NAME%%-${var.aws_region}` placeholder
- **Solution name references** are replaced with `%%SOLUTION_NAME%%` placeholder  
- **Version references** are replaced with `%%VERSION%%` placeholder

These placeholders are then replaced with actual values during the build process.

### 📦 Lambda Function Processing

Identifies and catalogs Lambda functions in the solution:

- Detects runtime (Node.js, Python, etc.)
- Identifies handler functions
- Generates metadata for packaging
- Creates deployment manifests

### 📋 Deployment Manifest Generation

Creates comprehensive deployment documentation:

- Lists all components and their locations
- Documents deployment steps
- Provides configuration guidance

## Usage

### Prerequisites

- Node.js 12.x or later
- npm or yarn package manager

### Installation

```bash
cd terraform-solution-helper
npm install
```

### Running the Helper

```bash
npm start
# or
node index.js
```

## Example Transformations

### Terraform Variable File

**Before:**
```hcl
variable "artifact_bucket" {
  description = "S3 bucket containing Lambda deployment packages"
  type        = string
  default     = "my-custom-bucket-us-east-1"
}

variable "solution_version" {
  description = "Solution version"
  type        = string
  default     = "v1.0.0"
}
```

**After Helper Processing:**
```hcl
variable "artifact_bucket" {
  description = "S3 bucket containing Lambda deployment packages"
  type        = string
  default     = "${%%BUCKET_NAME%%}-${var.aws_region}"
}

variable "solution_version" {
  description = "Solution version"
  type        = string
  default     = "%%VERSION%%"
}
```

**After Build Script:**
```hcl
variable "artifact_bucket" {
  description = "S3 bucket containing Lambda deployment packages"
  type        = string
  default     = "${solutions}-${var.aws_region}"
}

variable "solution_version" {
  description = "Solution version"
  type        = string
  default     = "v2.1.0"
}
```

### Terraform Main Configuration

**Before:**
```hcl
resource "aws_s3_bucket_object" "lambda_package" {
  bucket = "my-deployment-bucket-us-east-1"
  key    = "live-streaming/v1.0.0/custom-resource.zip"
  source = "../source/custom-resource.zip"
}

resource "aws_lambda_function" "custom_resource" {
  function_name = "live-streaming-custom-resource"
  s3_bucket     = "my-deployment-bucket-us-east-1"
  s3_key        = "live-streaming/v1.0.0/custom-resource.zip"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda_role.arn
}
```

**After Helper Processing:**
```hcl
resource "aws_s3_bucket_object" "lambda_package" {
  bucket = "${%%BUCKET_NAME%%}-${var.aws_region}"
  key    = "%%SOLUTION_NAME%%/%%VERSION%%/custom-resource.zip"
  source = "../source/custom-resource.zip"
}

resource "aws_lambda_function" "custom_resource" {
  function_name = "%%SOLUTION_NAME%%-custom-resource"
  s3_bucket     = "${%%BUCKET_NAME%%}-${var.aws_region}"
  s3_key        = "%%SOLUTION_NAME%%/%%VERSION%%/custom-resource.zip"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda_role.arn
}
```

**After Build Script (deployment):**
```hcl
resource "aws_s3_bucket_object" "lambda_package" {
  bucket = "solutions-us-east-1"
  key    = "live-streaming-on-aws/v2.1.0/custom-resource.zip"
  source = "../source/custom-resource.zip"
}

resource "aws_lambda_function" "custom_resource" {
  function_name = "live-streaming-on-aws-custom-resource"
  s3_bucket     = "solutions-us-east-1"
  s3_key        = "live-streaming-on-aws/v2.1.0/custom-resource.zip"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda_role.arn
}
```

## Output Files

The helper generates the following files in `deployment/regional-s3-assets/`:

### Lambda Function Metadata
For each Lambda function, creates a metadata JSON file:
```json
{
  "functionName": "custom-resource",
  "runtime": "nodejs18.x",
  "handler": "index.handler",
  "bucketPlaceholder": "%%BUCKET_NAME%%",
  "keyPlaceholder": "%%SOLUTION_NAME%%/%%VERSION%%/custom-resource.zip"
}
```

### Pipeline Variables
`pipeline-variables.json`:
```json
{
  "deployment": {
    "bucket_name": "%%BUCKET_NAME%%",
    "solution_name": "%%SOLUTION_NAME%%",
    "version": "%%VERSION%%",
    "description": "These variables are replaced during the build process"
  },
  "instructions": {
    "bucket_name": "Will be replaced with: <bucket-name>-<region>",
    "solution_name": "Will be replaced with the solution name",
    "version": "Will be replaced with the solution version"
  }
}
```

### Deployment Manifest
`deployment-manifest.json`:
```json
{
  "solution": "%%SOLUTION_NAME%%",
  "version": "%%VERSION%%",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "infrastructure": "terraform",
  "components": {
    "terraform_configs": "terraform/",
    "lambda_functions": "source/custom-resource/",
    "deployment_assets": "deployment/regional-s3-assets/"
  },
  "deployment_instructions": {
    "step1": "Upload Lambda deployment packages to S3",
    "step2": "Update terraform.tfvars with artifact_bucket and solution_version",
    "step3": "Run terraform init and terraform apply"
  }
}
```

## Integration with Build Pipeline

This helper is designed to integrate with the AWS Solutions build pipeline:

1. **Helper runs first**: Processes Terraform configs and Lambda functions
2. **Build script runs**: Replaces placeholders with actual values
3. **Packaging occurs**: Lambda functions are zipped and uploaded to S3
4. **Deployment happens**: Terraform applies the configuration

### Build Script Integration

Your `build-s3-dist.sh` should include:

```bash
#!/bin/bash

# Run the helper
cd terraform-solution-helper
npm install
node index.js
cd ..

# Replace placeholders
find deployment/regional-s3-assets -type f -exec sed -i \
  -e "s/%%BUCKET_NAME%%/${BUCKET_NAME}/g" \
  -e "s/%%SOLUTION_NAME%%/${SOLUTION_NAME}/g" \
  -e "s/%%VERSION%%/${VERSION}/g" {} +

# Package Lambda functions
# ... (your packaging logic)

# Upload to S3
# ... (your upload logic)
```

## Directory Structure

```
.
├── index.js                          # Main helper script
├── package.json                      # Node.js dependencies
├── README.md                         # This file
└── deployment/
    └── regional-s3-assets/           # Output directory
        ├── custom-resource-metadata.json
        ├── pipeline-variables.json
        └── deployment-manifest.json
```

## Development

### Running Tests
```bash
npm test
```

### Adding New Features

To add support for additional Terraform patterns:

1. Add a new replacement function in `index.js`
2. Update the `processTerraformConfigs()` function
3. Document the transformation in this README

## Differences from CDK Solution Helper

This Terraform version differs from the CDK/CloudFormation helper in several ways:

| Feature | CDK Helper | Terraform Helper |
|---------|-----------|------------------|
| **Input Format** | CloudFormation JSON templates | Terraform .tf files (HCL) |
| **Processing** | JSON parsing and manipulation | Text-based pattern matching |
| **Asset Parameters** | Removes AssetParameter sections | Replaces variable defaults |
| **Nested Stacks** | Handles CloudFormation nested stacks | Handles Terraform modules |
| **Output** | Modified JSON templates | Modified HCL files + metadata |

## Troubleshooting

### Common Issues

**Issue**: "No Terraform directory found"
- **Solution**: Ensure the script is run from the correct directory with `../terraform` available

**Issue**: "Permission denied" errors
- **Solution**: Ensure the script has execute permissions: `chmod +x index.js`

**Issue**: Placeholders not being replaced
- **Solution**: Verify the build script is running the replacement correctly

## License

This project is licensed under the Apache License 2.0. See the LICENSE file for details.

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

**Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.**  
**SPDX-License-Identifier: Apache-2.0**