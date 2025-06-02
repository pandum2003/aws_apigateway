# AWS API Gateway S3 Upload Infrastructure

This Terraform project configures an AWS API Gateway that enables secure file uploads to an S3 bucket using API key authentication. The API Gateway is set up with a Regional endpoint and supports nested path parameters for organizing uploaded files.

## Architecture

- **API Gateway**: Regional endpoint with API key authentication
- **Integration**: Direct integration with S3 for file uploads
- **Path Structure**: `/{objectpath}/{objectname}` for flexible file organization
- **Security**: API key required for all requests
- **Throttling**: Configurable rate limits and usage plans

## Prerequisites

- Terraform >= 1.0.0
- AWS account and credentials configured
- Existing S3 bucket
- IAM role with permissions to upload to S3

## Module Structure

```
apigateway/
├── main.tf           # Root module configuration
├── variables.tf      # Root module variables
├── outputs.tf        # Root module outputs
├── providers.tf      # Provider configuration
└── modules/
    └── api_gateway/  # API Gateway module
        ├── main.tf           # Module resources
        ├── variables.tf      # Module variables
        └── outputs.tf        # Module outputs
```

## Usage

1. Initialize Terraform:
```bash
terraform init
```

2. Create a `terraform.tfvars` file with your configuration:
```hcl
aws_region     = "us-east-1"
api_name       = "s3-upload-api"
s3_bucket_name = "your-bucket-name"
iam_role_arn   = "arn:aws:iam::123456789012:role/api-gateway-s3-role"
stage_name     = "prod"  # optional, defaults to "prod"
```

3. Review the planned changes:
```bash
terraform plan
```

4. Apply the configuration:
```bash
terraform apply
```

## API Endpoints

The API Gateway creates two PUT endpoints:

1. Path-level upload: `PUT /{stage}/{objectpath}`
2. Name-level upload: `PUT /{stage}/{objectpath}/{objectname}`

Both endpoints require:
- API Key in `x-api-key` header
- Content-Type header
- Binary payload (the file content)

## Resource Quotas and Limits

- Monthly quota: 1,000,000 requests per month
- Burst limit: 500 requests
- Rate limit: 1,000 requests per second

## Outputs

- `api_endpoint`: The base URL of the API Gateway
- `api_key`: The API key for authentication (sensitive value)
- `rest_api_id`: The ID of the REST API
- `stage_name`: The name of the deployed stage

## Example Usage

Using curl to upload a file:
```bash
# Upload to path level
curl -X PUT \
  "https://{api-id}.execute-api.{region}.amazonaws.com/{stage}/folder1" \
  -H "x-api-key: your-api-key" \
  -H "Content-Type: application/octet-stream" \
  --data-binary "@file.txt"

# Upload with specific name
curl -X PUT \
  "https://{api-id}.execute-api.{region}.amazonaws.com/{stage}/folder1/file.txt" \
  -H "x-api-key: your-api-key" \
  -H "Content-Type: application/octet-stream" \
  --data-binary "@file.txt"
```

## IAM Role Requirements

The IAM role specified in `iam_role_arn` must have the following permissions:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::${bucket_name}/*"
            ]
        }
    ]
}
```

## Notes

- The API Gateway uses a Regional endpoint type for better performance within the same region
- All requests require an API key for authentication
- Binary payloads are supported through `binary_media_types = ["*/*"]`
- CORS headers are included in responses
- The deployment includes triggers to ensure proper redeployment when resources change

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
