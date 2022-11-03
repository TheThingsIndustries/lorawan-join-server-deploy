output "region" {
  description = "AWS region"
  value       = var.region
}

output "source_s3_bucket" {
  description = "AWS S3 bucket of the source assets"
  value       = local.s3_bucket
}

output "source_s3_code_key" {
  description = "AWS S3 bucket key of the source assets"
  value       = local.s3_code_key
}

output "authorizer_function" {
  description = "AWS Lambda authorizer function name"
  value       = local.authorizer_function
}

output "openapi_function" {
  description = "AWS Lambda function name for OpenAPI"
  value       = local.openapi_function
}

output "backendinterfaces_function" {
  description = "AWS Lambda function name for LoRaWAN Backend Interfaces"
  value       = local.backendinterfaces_function
}

output "provisioning_function" {
  description = "AWS Lambda function name for provisioning"
  value       = local.provisioning_function
}

output "claiming_function" {
  description = "AWS Lambda function name for claiming"
  value       = local.claiming_function
}

output "url" {
  description = "The Things Join Server URL"
  value       = local.public_url
}

output "openapi_url" {
  description = "OpenAPI URL"
  value       = "${local.public_url}/api/v2/openapi.json"
}

output "root_provisioner_password" {
  description = "Root Provisioner password"
  sensitive   = true
  value       = random_password.root_provisioner_password.result
}

output "network_server_passwords" {
  description = "Network Server passwords"
  sensitive   = true
  value = [
    for key, value in var.network_servers : {
      username = key
      name     = value.name
      password = random_password.network_server_password[key].result
    }
  ]
}

output "application_server_passwords" {
  description = "Application Server passwords"
  sensitive   = true
  value = [
    for key, value in var.application_servers : {
      username = key
      name     = value.name
      password = random_password.application_server_password[key].result
    }
  ]
}

output "domain_target" {
  description = "Target name to configure as DNS CNAME record of your domain"
  value       = var.domain != "" ? aws_apigatewayv2_domain_name.domain[0].domain_name_configuration[0].target_domain_name : ""
}
