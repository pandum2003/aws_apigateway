module "api_gateway" {
  source = "./modules/api_gateway"

  aws_region     = var.aws_region
  api_name       = var.api_name
  s3_bucket_name = var.s3_bucket_name
  iam_role_arn   = var.iam_role_arn
  stage_name     = var.stage_name
}


