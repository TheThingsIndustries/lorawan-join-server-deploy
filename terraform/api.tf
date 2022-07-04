resource "aws_apigatewayv2_api" "api" {
  name          = var.resource_prefix
  protocol_type = "HTTP"
  cors_configuration {
    allow_headers = ["Authorization", "X-Request-With"]
    allow_methods = ["GET", "PUT", "POST", "DELETE"]
    allow_origins = ["*"]
  }
}

resource "aws_apigatewayv2_stage" "api" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_iam_role" "authorizer" {
  name = local.authorizer_function

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "authorizer" {
  name = "${var.resource_prefix}-authorizer"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParametersByPath"
      ],
      "Resource": "arn:aws:ssm:*:*:parameter/${var.ssm_parameter_prefix}/*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_lambda_function" "authorizer" {
  function_name = local.authorizer_function
  role          = aws_iam_role.authorizer.arn
  handler       = "dist/aws/lambda.authorizerHandler"

  s3_bucket = local.s3_bucket
  s3_key    = local.s3_code_key

  runtime       = "nodejs14.x"
  architectures = ["arm64"]

  environment {
    variables = local.function_environment
  }

  depends_on = [
    aws_iam_role_policy_attachment.authorizer,
    aws_iam_role_policy_attachment.authorizer_logging,
  ]
}

resource "aws_iam_role_policy_attachment" "authorizer" {
  role       = aws_iam_role.authorizer.name
  policy_arn = aws_iam_policy.authorizer.arn
}

resource "aws_iam_role_policy_attachment" "authorizer_logging" {
  role       = aws_iam_role.authorizer.name
  policy_arn = aws_iam_policy.logging.arn
}

# There are two API Gateway authorizers: the required and optional authorizer. Both use the same Lambda.
#
# The required authorizer requires the Authorization header to be present. This authorizer uses caching and is therefore
# preferred. The optional authorizer does not use caching and is called on every request. This should only be used for
# routes where authentication is optional.

resource "aws_apigatewayv2_authorizer" "required_authorizer" {
  api_id                            = aws_apigatewayv2_api.api.id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = aws_lambda_function.authorizer.invoke_arn
  authorizer_payload_format_version = "2.0"
  authorizer_result_ttl_in_seconds  = 300
  enable_simple_responses           = true
  identity_sources                  = ["$request.header.Authorization"]
  name                              = "RequiredBasicAuth"
}

resource "aws_lambda_permission" "required_authorizer_api" {
  statement_id  = "InvokeByRequiredBasicAuthAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/authorizers/${aws_apigatewayv2_authorizer.required_authorizer.id}"
}

resource "aws_apigatewayv2_authorizer" "optional_authorizer" {
  api_id                            = aws_apigatewayv2_api.api.id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = aws_lambda_function.authorizer.invoke_arn
  authorizer_payload_format_version = "2.0"
  authorizer_result_ttl_in_seconds  = 0
  enable_simple_responses           = true
  name                              = "OptionalBasicAuth"
}

resource "aws_lambda_permission" "optional_authorizer_api" {
  statement_id  = "InvokeByOptionalBasicAuthAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/authorizers/${aws_apigatewayv2_authorizer.optional_authorizer.id}"
}

# Lambda integrations

resource "aws_apigatewayv2_integration" "openapi" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"

  connection_type        = "INTERNET"
  description            = "OpenAPI"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.openapi.invoke_arn
  passthrough_behavior   = "WHEN_NO_MATCH"
  timeout_milliseconds   = 5000
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_integration" "provisioning" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"

  connection_type        = "INTERNET"
  description            = "Claiming"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.provisioning.invoke_arn
  passthrough_behavior   = "WHEN_NO_MATCH"
  # This is the maximum value; longer requests fail with HTTP 503 but continue for 5 minutes, see functions.tf.
  timeout_milliseconds   = 29000
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_integration" "claiming" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"

  connection_type        = "INTERNET"
  description            = "Claiming"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.claiming.invoke_arn
  passthrough_behavior   = "WHEN_NO_MATCH"
  timeout_milliseconds   = 5000
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_integration" "clients" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"

  connection_type        = "INTERNET"
  description            = "Clients"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.clients.invoke_arn
  passthrough_behavior   = "WHEN_NO_MATCH"
  timeout_milliseconds   = 5000
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_integration" "backendinterfaces" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"

  connection_type        = "INTERNET"
  description            = "LoRaWAN Backend Interfaces"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.backendinterfaces.invoke_arn
  passthrough_behavior   = "WHEN_NO_MATCH"
  timeout_milliseconds   = 5000
  payload_format_version = "1.0"
}

# Routes

resource "aws_apigatewayv2_route" "get_openapi" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "GET /v1/openapi.json"
  target             = "integrations/${aws_apigatewayv2_integration.openapi.id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_route" "get_formats" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "GET /v1/provision/formats"
  target             = "integrations/${aws_apigatewayv2_integration.provisioning.id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_route" "get_provisioned_device" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "GET /v1/provision/{devEUI}"
  target             = "integrations/${aws_apigatewayv2_integration.provisioning.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.required_authorizer.id
}

resource "aws_apigatewayv2_route" "provision" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "POST /v1/provision/{format}"
  target             = "integrations/${aws_apigatewayv2_integration.provisioning.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.optional_authorizer.id
}

resource "aws_apigatewayv2_route" "get_claim" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "GET /v1/claim/{devEUI}"
  target             = "integrations/${aws_apigatewayv2_integration.claiming.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.required_authorizer.id
}

resource "aws_apigatewayv2_route" "create_claim" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "POST /v1/claim/{devEUI}"
  target             = "integrations/${aws_apigatewayv2_integration.claiming.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.required_authorizer.id
}

resource "aws_apigatewayv2_route" "update_claim" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "PUT /v1/claim/{devEUI}"
  target             = "integrations/${aws_apigatewayv2_integration.claiming.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.required_authorizer.id
}

resource "aws_apigatewayv2_route" "delete_claim" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "DELETE /v1/claim/{devEUI}"
  target             = "integrations/${aws_apigatewayv2_integration.claiming.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.required_authorizer.id
}

resource "aws_apigatewayv2_route" "get_network_server" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "GET /v1/clients/ns/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.clients.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.required_authorizer.id
}

resource "aws_apigatewayv2_route" "create_network_server" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "POST /v1/clients/ns/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.clients.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.required_authorizer.id
}

resource "aws_apigatewayv2_route" "delete_network_server" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "DELETE /v1/clients/ns/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.clients.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.required_authorizer.id
}

resource "aws_apigatewayv2_route" "update_network_server_kek" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "PUT /v1/clients/ns/{id}/kek"
  target             = "integrations/${aws_apigatewayv2_integration.clients.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.required_authorizer.id
}

resource "aws_apigatewayv2_route" "get_application_server" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "GET /v1/clients/as/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.clients.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.required_authorizer.id
}

resource "aws_apigatewayv2_route" "create_application_server" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "POST /v1/clients/as/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.clients.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.required_authorizer.id
}

resource "aws_apigatewayv2_route" "delete_application_server" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "DELETE /v1/clients/as/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.clients.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.required_authorizer.id
}

resource "aws_apigatewayv2_route" "update_application_server_kek" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "PUT /v1/clients/as/{id}/kek"
  target             = "integrations/${aws_apigatewayv2_integration.clients.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.required_authorizer.id
}

resource "aws_apigatewayv2_route" "backendinterfaces" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "POST /"
  target             = "integrations/${aws_apigatewayv2_integration.backendinterfaces.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.required_authorizer.id
}
