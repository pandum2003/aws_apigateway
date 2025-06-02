output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = module.api_gateway.api_endpoint
}

output "api_key" {
  description = "API Key for authentication"
  value       = module.api_gateway.api_key
  sensitive   = true
}

output "rest_api_id" {
  description = "ID of the REST API"
  value       = module.api_gateway.rest_api_id
}

output "stage_name" {
  description = "Name of the API Gateway stage"
  value       = module.api_gateway.stage_name
}