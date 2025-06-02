resource "aws_api_gateway_rest_api" "s3_api" {
  name = var.api_name
  description = "API Gateway for S3 file uploads"
  binary_media_types = ["*/*"]

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Resource for object path
resource "aws_api_gateway_resource" "object_path" {
  rest_api_id = aws_api_gateway_rest_api.s3_api.id
  parent_id   = aws_api_gateway_rest_api.s3_api.root_resource_id
  path_part   = "{objectpath}"
}

# Resource for objectname under objectpath
resource "aws_api_gateway_resource" "object_name" {
  rest_api_id = aws_api_gateway_rest_api.s3_api.id
  parent_id   = aws_api_gateway_resource.object_path.id
  path_part   = "{objectname}"
}

# PUT method for object upload at path level
resource "aws_api_gateway_method" "put_method_path" {
  rest_api_id      = aws_api_gateway_rest_api.s3_api.id
  resource_id      = aws_api_gateway_resource.object_path.id
  http_method      = "PUT"
  authorization    = "NONE"
  api_key_required = true

  request_parameters = {
    "method.request.path.objectpath" = true
    "method.request.header.Content-Type" = true
  }
}

# PUT method for object upload at name level
resource "aws_api_gateway_method" "put_method_name" {
  rest_api_id      = aws_api_gateway_rest_api.s3_api.id
  resource_id      = aws_api_gateway_resource.object_name.id
  http_method      = "PUT"
  authorization    = "NONE"
  api_key_required = true

  request_parameters = {
    "method.request.path.objectpath" = true
    "method.request.path.objectname" = true
    "method.request.header.Content-Type" = true
  }
}

# Integration with S3 at path level
resource "aws_api_gateway_integration" "s3_integration_path" {
  rest_api_id = aws_api_gateway_rest_api.s3_api.id
  resource_id = aws_api_gateway_resource.object_path.id
  http_method = aws_api_gateway_method.put_method_path.http_method
  integration_http_method = "PUT"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.aws_region}:s3:path/${var.s3_bucket_name}/{objectpath}"
  credentials             = var.iam_role_arn
  passthrough_behavior    = "WHEN_NO_MATCH"

  request_parameters = {
    "integration.request.path.objectpath" = "method.request.path.objectpath"
    "integration.request.header.Content-Type" = "method.request.header.Content-Type"
  }
}

# Integration with S3 at name level
resource "aws_api_gateway_integration" "s3_integration_name" {
  rest_api_id = aws_api_gateway_rest_api.s3_api.id
  resource_id = aws_api_gateway_resource.object_name.id
  http_method = aws_api_gateway_method.put_method_name.http_method
  integration_http_method = "PUT"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.aws_region}:s3:path/${var.s3_bucket_name}/{objectpath}/{objectname}"
  credentials             = var.iam_role_arn
  passthrough_behavior    = "WHEN_NO_MATCH"

  request_parameters = {
    "integration.request.path.objectpath" = "method.request.path.objectpath"
    "integration.request.path.objectname" = "method.request.path.objectname"
    "integration.request.header.Content-Type" = "method.request.header.Content-Type"
  }
}

# Method response for path level
resource "aws_api_gateway_method_response" "response_200_path" {
  rest_api_id = aws_api_gateway_rest_api.s3_api.id
  resource_id = aws_api_gateway_resource.object_path.id
  http_method = aws_api_gateway_method.put_method_path.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
    "method.response.header.Content-Type" = true
    "method.response.header.Content-Length" = true
  }
}

# Method response for name level
resource "aws_api_gateway_method_response" "response_200_name" {
  rest_api_id = aws_api_gateway_rest_api.s3_api.id
  resource_id = aws_api_gateway_resource.object_name.id
  http_method = aws_api_gateway_method.put_method_name.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
    "method.response.header.Content-Type" = true
    "method.response.header.Content-Length" = true
  }
}

# Integration response for path level
resource "aws_api_gateway_integration_response" "s3_integration_response_path" {
  rest_api_id = aws_api_gateway_rest_api.s3_api.id
  resource_id = aws_api_gateway_resource.object_path.id
  http_method = aws_api_gateway_method.put_method_path.http_method
  status_code = aws_api_gateway_method_response.response_200_path.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
    "method.response.header.Content-Type" = "integration.response.header.Content-Type"
    "method.response.header.Content-Length" = "integration.response.header.Content-Length"
  }
}

# Integration response for name level
resource "aws_api_gateway_integration_response" "s3_integration_response_name" {
  rest_api_id = aws_api_gateway_rest_api.s3_api.id
  resource_id = aws_api_gateway_resource.object_name.id
  http_method = aws_api_gateway_method.put_method_name.http_method
  status_code = aws_api_gateway_method_response.response_200_name.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
    "method.response.header.Content-Type" = "integration.response.header.Content-Type"
    "method.response.header.Content-Length" = "integration.response.header.Content-Length"
  }

  depends_on = [aws_api_gateway_integration.s3_integration_path, aws_api_gateway_integration.s3_integration_name]
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.s3_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_integration.s3_integration_path,
      aws_api_gateway_integration.s3_integration_name,
      aws_api_gateway_method.put_method_path,
      aws_api_gateway_method.put_method_name,
      aws_api_gateway_method_response.response_200_path,
      aws_api_gateway_method_response.response_200_name,
      aws_api_gateway_integration_response.s3_integration_response_path,
      aws_api_gateway_integration_response.s3_integration_response_name
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.s3_integration_path,
    aws_api_gateway_integration.s3_integration_name,
    aws_api_gateway_integration_response.s3_integration_response_path,
    aws_api_gateway_integration_response.s3_integration_response_name,
    aws_api_gateway_method.put_method_path,
    aws_api_gateway_method.put_method_name,
    aws_api_gateway_method_response.response_200_path,
    aws_api_gateway_method_response.response_200_name
  ]
}

# API Gateway Stage
resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id  = aws_api_gateway_rest_api.s3_api.id
  stage_name   = var.stage_name
}

# API Key
resource "aws_api_gateway_api_key" "api_key" {
  name = "${var.api_name}-key"
}

# Usage Plan
resource "aws_api_gateway_usage_plan" "usage_plan" {
  name = "${var.api_name}-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.s3_api.id
    stage  = aws_api_gateway_stage.api_stage.stage_name
  }

  quota_settings {
    limit  = 1000000
    period = "MONTH"
  }

  throttle_settings {
    burst_limit = 500
    rate_limit  = 1000
  }
}

# Usage Plan Key
resource "aws_api_gateway_usage_plan_key" "usage_plan_key" {
  key_id        = aws_api_gateway_api_key.api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.usage_plan.id
}
