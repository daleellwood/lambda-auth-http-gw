# HTTP API Gateway with Lambda Authorizer

This repository contains Terraform configuration for setting up an AWS HTTP API Gateway with a Lambda authorizer that performs IP-based access control.

## Architecture

The setup includes:

- **HTTP API Gateway**: Main entry point for API requests
- **Lambda Authorizer**: Custom authorizer function that validates requests based on source IP
- **VPC Link**: Connects API Gateway to backend services in a VPC
- **IAM Roles & Policies**: Proper permissions for API Gateway to invoke the Lambda authorizer

## Components

### Files

- `api-http.tf` - HTTP API Gateway configuration with authorizer
- `lambda.tf` - Lambda function and IAM role configuration
- `vpc_link.tf` - VPC Link and security group configuration
- `data.tf` - Data sources for existing AWS resources
- `var.tf` - Variable definitions
- `lambda_authorizer.py` - Lambda authorizer function code

### Key Features

1. **IP-based Authorization**: The Lambda authorizer checks the source IP against a configurable whitelist
2. **CIDR Support**: Supports both individual IP addresses and CIDR blocks
3. **VPC Integration**: Uses VPC Link to connect to backend services securely
4. **Logging**: Comprehensive CloudWatch logging for both API Gateway and Lambda

## Usage

1. Update the variables in `var.tf` or create a `terraform.tfvars` file:

```hcl
vpc_name             = "my-vpc"
backend_lb_name      = "my-backend-lb"
private_subnet_names = ["private-subnet-1", "private-subnet-2"]
domain_name          = "example.com"
allowed_ips          = ["203.0.113.0/24", "198.51.100.1"]
```

2. Deploy with Terraform:

```bash
terraform init
terraform plan
terraform apply
```

## Lambda Authorizer Logic

The Lambda authorizer (`lambda_authorizer.py`) performs the following:

1. Extracts the source IP from the API Gateway request
2. Compares it against the configured IP whitelist (supports CIDR notation)
3. Returns an IAM policy allowing or denying the request
4. Logs all authorization decisions for auditing

## Security Considerations

- The authorizer uses a TTL of 0 to ensure real-time IP checking
- All requests are logged for security auditing
- The VPC Link ensures backend traffic stays within your VPC
- IAM roles follow the principle of least privilege

## Customization

To modify the authorization logic:

1. Edit `lambda_authorizer.py` to implement your custom logic
2. Update the environment variables in `lambda.tf` if needed
3. Redeploy with `terraform apply`

## Requirements

- Terraform >= 0.14
- AWS Provider >= 3.0
- Existing VPC with private subnets
- Backend load balancer for integration