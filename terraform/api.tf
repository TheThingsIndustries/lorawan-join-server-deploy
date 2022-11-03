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

  connection_type      = "INTERNET"
  description          = "Claiming"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.provisioning.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"
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
  route_key          = "GET /api/v2/openapi.json"
  target             = "integrations/${aws_apigatewayv2_integration.openapi.id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_route" "get_devices_import_formats" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "GET /api/v2/devices/import/formats"
  target             = "integrations/${aws_apigatewayv2_integration.provisioning.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.required_authorizer.id
}

resource "aws_apigatewayv2_route" "post_devices_import" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "POST /api/v2/devices/import/{format}"
  target             = "integrations/${aws_apigatewayv2_integration.provisioning.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.required_authorizer.id
}

resource "aws_apigatewayv2_route" "get_devices" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "GET /api/v2/devices"
  target             = "integrations/${aws_apigatewayv2_integration.provisioning.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.required_authorizer.id
}

resource "aws_apigatewayv2_route" "get_device" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "GET /api/v2/devices/{devEUI}"
  target             = "integrations/${aws_apigatewayv2_integration.provisioning.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.required_authorizer.id
}

resource "aws_apigatewayv2_route" "get_device_claim" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "GET /api/v2/devices/{devEUI}/claim"
  target             = "integrations/${aws_apigatewayv2_integration.claiming.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.required_authorizer.id
}

resource "aws_apigatewayv2_route" "put_device_claim" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "PUT /api/v2/devices/{devEUI}/claim"
  target             = "integrations/${aws_apigatewayv2_integration.claiming.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.required_authorizer.id
}

resource "aws_apigatewayv2_route" "delete_device_claim" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "DELETE /api/v2/devices/{devEUI}/claim"
  target             = "integrations/${aws_apigatewayv2_integration.claiming.id}"
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
