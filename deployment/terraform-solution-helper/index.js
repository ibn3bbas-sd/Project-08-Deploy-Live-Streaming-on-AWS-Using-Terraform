// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

/**
 * Terraform Solution Helper
 * Prepares Terraform configurations and Lambda deployment packages for the AWS Solutions publishing pipeline
 */

const fs = require('fs');
const path = require('path');

// Paths
const terraform_configs = '../terraform';
const lambda_functions = '../source/custom-resource';
const output_dir = '../deployment/regional-s3-assets';

// Placeholder patterns for replacement
const PLACEHOLDERS = {
  BUCKET_NAME: '%%BUCKET_NAME%%',
  SOLUTION_NAME: '%%SOLUTION_NAME%%',
  VERSION: '%%VERSION%%'
};

/**
 * Process Lambda function source code for packaging
 */
function processLambdaFunctions() {
  console.log('Processing Lambda functions...');
  
  if (!fs.existsSync(lambda_functions)) {
    console.log('No Lambda functions directory found, skipping...');
    return;
  }

  // Create output directory if it doesn't exist
  if (!fs.existsSync(output_dir)) {
    fs.mkdirSync(output_dir, { recursive: true });
  }

  // Find all Lambda function directories
  const functionDirs = fs.readdirSync(lambda_functions, { withFileTypes: true })
    .filter(dirent => dirent.isDirectory())
    .map(dirent => dirent.name);

  functionDirs.forEach(funcDir => {
    const funcPath = path.join(lambda_functions, funcDir);
    const packageJson = path.join(funcPath, 'package.json');

    if (fs.existsSync(packageJson)) {
      console.log(`  Found Lambda function: ${funcDir}`);
      
      // Create function-specific metadata
      const metadata = {
        functionName: funcDir,
        runtime: detectRuntime(funcPath),
        handler: detectHandler(funcPath),
        bucketPlaceholder: PLACEHOLDERS.BUCKET_NAME,
        keyPlaceholder: `${PLACEHOLDERS.SOLUTION_NAME}/${PLACEHOLDERS.VERSION}/${funcDir}.zip`
      };

      // Write metadata file
      const metadataPath = path.join(output_dir, `${funcDir}-metadata.json`);
      fs.writeFileSync(metadataPath, JSON.stringify(metadata, null, 2));
      console.log(`    Created metadata: ${funcDir}-metadata.json`);
    }
  });
}

/**
 * Process Terraform configuration files
 */
function processTerraformConfigs() {
  console.log('Processing Terraform configurations...');

  if (!fs.existsSync(terraform_configs)) {
    console.log('No Terraform directory found, skipping...');
    return;
  }

  // Find all .tf files
  const tfFiles = fs.readdirSync(terraform_configs)
    .filter(file => file.endsWith('.tf'));

  tfFiles.forEach(file => {
    const filePath = path.join(terraform_configs, file);
    let content = fs.readFileSync(filePath, 'utf8');

    console.log(`  Processing: ${file}`);

    // Replace hardcoded bucket names with placeholders
    content = replaceBucketReferences(content);

    // Replace hardcoded solution names with placeholders
    content = replaceSolutionReferences(content);

    // Replace version references
    content = replaceVersionReferences(content);

    // Write processed file
    fs.writeFileSync(filePath, content);
    console.log(`    Updated with placeholders`);
  });
}

/**
 * Replace bucket name references with placeholders
 */
function replaceBucketReferences(content) {
  // Match S3 bucket references in Terraform
  const bucketPatterns = [
    // Direct bucket name in variables
    /bucket\s*=\s*"([^"]+)"/g,
    // S3 bucket resource names
    /s3:\/\/([a-z0-9\-\.]+)/g,
    // Artifact bucket references
    /artifact_bucket\s*=\s*"([^"]+)"/g
  ];

  bucketPatterns.forEach(pattern => {
    content = content.replace(pattern, (match, bucketName) => {
      if (bucketName && !bucketName.includes('%%') && !bucketName.includes('${')) {
        // Keep the structure but use placeholder
        return match.replace(bucketName, `\${${PLACEHOLDERS.BUCKET_NAME}}-\${var.aws_region}`);
      }
      return match;
    });
  });

  return content;
}

/**
 * Replace solution name references with placeholders
 */
function replaceSolutionReferences(content) {
  // Match common solution name patterns
  const patterns = [
    /solution_name\s*=\s*"([^"]+)"/g,
    /project_name\s*=\s*"([^"]+)"/g
  ];

  patterns.forEach(pattern => {
    content = content.replace(pattern, (match, name) => {
      if (name && !name.includes('%%')) {
        return match.replace(name, PLACEHOLDERS.SOLUTION_NAME);
      }
      return match;
    });
  });

  return content;
}

/**
 * Replace version references with placeholders
 */
function replaceVersionReferences(content) {
  const versionPattern = /solution_version\s*=\s*"([^"]+)"/g;
  
  return content.replace(versionPattern, (match, version) => {
    if (version && !version.includes('%%')) {
      return match.replace(version, PLACEHOLDERS.VERSION);
    }
    return match;
  });
}

/**
 * Detect runtime from Lambda function directory
 */
function detectRuntime(funcPath) {
  if (fs.existsSync(path.join(funcPath, 'package.json'))) {
    const packageJson = JSON.parse(fs.readFileSync(path.join(funcPath, 'package.json')));
    return packageJson.engines && packageJson.engines.node 
      ? `nodejs${packageJson.engines.node.replace(/[^\d.]/g, '')}` 
      : 'nodejs18.x';
  }
  
  if (fs.existsSync(path.join(funcPath, 'requirements.txt'))) {
    return 'python3.11';
  }

  return 'nodejs18.x'; // default
}

/**
 * Detect handler from Lambda function
 */
function detectHandler(funcPath) {
  // Check for common handler files
  const handlers = [
    'index.js',
    'index.ts',
    'main.py',
    'lambda_function.py',
    'handler.js',
    'handler.py'
  ];

  for (const handler of handlers) {
    if (fs.existsSync(path.join(funcPath, handler))) {
      const ext = path.extname(handler);
      const base = path.basename(handler, ext);
      return ext === '.py' ? `${base}.lambda_handler` : `${base}.handler`;
    }
  }

  return 'index.handler'; // default
}

/**
 * Generate Terraform variables file for pipeline
 */
function generatePipelineVariables() {
  console.log('Generating pipeline variables...');

  const pipelineVars = {
    deployment: {
      bucket_name: PLACEHOLDERS.BUCKET_NAME,
      solution_name: PLACEHOLDERS.SOLUTION_NAME,
      version: PLACEHOLDERS.VERSION,
      description: 'These variables are replaced during the build process'
    },
    instructions: {
      bucket_name: 'Will be replaced with: <bucket-name>-<region>',
      solution_name: 'Will be replaced with the solution name',
      version: 'Will be replaced with the solution version'
    }
  };

  const pipelineVarsPath = path.join(output_dir, 'pipeline-variables.json');
  fs.writeFileSync(pipelineVarsPath, JSON.stringify(pipelineVars, null, 2));
  console.log('  Created pipeline-variables.json');
}

/**
 * Create deployment manifest
 */
function createDeploymentManifest() {
  console.log('Creating deployment manifest...');

  const manifest = {
    solution: PLACEHOLDERS.SOLUTION_NAME,
    version: PLACEHOLDERS.VERSION,
    timestamp: new Date().toISOString(),
    infrastructure: 'terraform',
    components: {
      terraform_configs: 'terraform/',
      lambda_functions: 'source/custom-resource/',
      deployment_assets: 'deployment/regional-s3-assets/'
    },
    deployment_instructions: {
      step1: 'Upload Lambda deployment packages to S3',
      step2: 'Update terraform.tfvars with artifact_bucket and solution_version',
      step3: 'Run terraform init and terraform apply'
    }
  };

  const manifestPath = path.join(output_dir, 'deployment-manifest.json');
  fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2));
  console.log('  Created deployment-manifest.json');
}

/**
 * Main execution
 */
function main() {
  console.log('========================================');
  console.log('Terraform Solution Helper');
  console.log('========================================\n');

  try {
    // Process Lambda functions
    processLambdaFunctions();
    console.log();

    // Process Terraform configurations
    processTerraformConfigs();
    console.log();

    // Generate pipeline variables
    generatePipelineVariables();
    console.log();

    // Create deployment manifest
    createDeploymentManifest();
    console.log();

    console.log('========================================');
    console.log('Processing complete!');
    console.log('========================================');
    console.log('\nNext steps:');
    console.log('1. Review processed files in deployment/regional-s3-assets/');
    console.log('2. Package Lambda functions as .zip files');
    console.log('3. Run the build script to replace placeholders');
    console.log('4. Deploy using Terraform\n');

  } catch (error) {
    console.error('Error during processing:', error);
    process.exit(1);
  }
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = {
  processLambdaFunctions,
  processTerraformConfigs,
  replaceBucketReferences,
  replaceSolutionReferences,
  replaceVersionReferences
};