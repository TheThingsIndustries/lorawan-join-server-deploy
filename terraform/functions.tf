resource "aws_iam_policy" "logging" {
  name = "${var.resource_prefix}-logging"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "provisioning" {
  name = "${var.resource_prefix}-provisioning"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "iot:CreateThing",
        "iot:DescribeThing"
      ],
      "Resource": "arn:aws:iot:*:*:thing/*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/${aws_dynamodb_table.things.name}",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "claiming" {
  name = "${var.resource_prefix}-claiming"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "iot:DescribeThing",
        "iot:UpdateThing"
      ],
      "Resource": "arn:aws:iot:*:*:thing/*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:UpdateItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/${aws_dynamodb_table.things.name}",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "clients" {
  name = "${var.resource_prefix}-clients"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParametersByPath",
        "ssm:PutParameter",
        "ssm:DeleteParameter"
      ],
      "Resource": "arn:aws:ssm:*:*:parameter/${var.ssm_parameter_prefix}/*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "backendinterfaces" {
  name = "${var.resource_prefix}-backendinterfaces"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "iot:DescribeThing"
      ],
      "Resource": "arn:aws:iot:*:*:thing/*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/${aws_dynamodb_table.app_s_keys.name}",
      "Effect": "Allow"
    },
    {
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:UpdateItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/${aws_dynamodb_table.things.name}",
      "Effect": "Allow"
    },
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

resource "aws_iam_role" "backendinterfaces" {
  name = local.backendinterfaces_function

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

resource "aws_lambda_function" "backendinterfaces" {
  function_name = local.backendinterfaces_function
  role          = aws_iam_role.backendinterfaces.arn
  handler       = "dist/aws/lambda.backendInterfacesHandler"

  s3_bucket = local.s3_bucket
  s3_key    = local.s3_code_key

  runtime       = "nodejs14.x"
  architectures = ["arm64"]
  memory_size   = 256

  environment {
    variables = local.function_environment
  }

  depends_on = [
    aws_iam_role_policy_attachment.backendinterfaces,
    aws_iam_role_policy_attachment.backendinterfaces_logging,
  ]
}

resource "aws_iam_role_policy_attachment" "backendinterfaces" {
  role       = aws_iam_role.backendinterfaces.name
  policy_arn = aws_iam_policy.backendinterfaces.arn
}

resource "aws_iam_role_policy_attachment" "backendinterfaces_logging" {
  role       = aws_iam_role.backendinterfaces.name
  policy_arn = aws_iam_policy.logging.arn
}

resource "aws_lambda_permission" "backendinterfaces_api" {
  statement_id  = "InvokeByAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backendinterfaces.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_stage.api.execution_arn}/*"
}

resource "aws_iam_role" "openapi" {
  name = local.openapi_function

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

resource "aws_lambda_function" "openapi" {
  function_name = local.openapi_function
  role          = aws_iam_role.openapi.arn
  handler       = "dist/aws/lambda.openapiHandler"

  s3_bucket = local.s3_bucket
  s3_key    = local.s3_code_key

  runtime       = "nodejs14.x"
  architectures = ["arm64"]

  environment {
    variables = local.function_environment
  }

  depends_on = [
    aws_iam_role_policy_attachment.openapi_logging,
  ]
}

resource "aws_iam_role_policy_attachment" "openapi_logging" {
  role       = aws_iam_role.openapi.name
  policy_arn = aws_iam_policy.logging.arn
}

resource "aws_lambda_permission" "openapi_api" {
  statement_id  = "InvokeByAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.openapi.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_stage.api.execution_arn}/*"
}

resource "aws_iam_role" "provisioning" {
  name = local.provisioning_function

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

resource "aws_lambda_function" "provisioning" {
  function_name = local.provisioning_function
  role          = aws_iam_role.provisioning.arn
  handler       = "dist/aws/lambda.provisionHandler"

  s3_bucket = local.s3_bucket
  s3_key    = local.s3_code_key

  runtime       = "nodejs14.x"
  architectures = ["arm64"]
  memory_size   = 256

  environment {
    variables = local.function_environment
  }

  depends_on = [
    aws_iam_role_policy_attachment.provisioning,
    aws_iam_role_policy_attachment.provisioning_logging,
  ]
}

resource "aws_iam_role_policy_attachment" "provisioning" {
  role       = aws_iam_role.provisioning.name
  policy_arn = aws_iam_policy.provisioning.arn
}

resource "aws_iam_role_policy_attachment" "provisioning_logging" {
  role       = aws_iam_role.provisioning.name
  policy_arn = aws_iam_policy.logging.arn
}

resource "aws_lambda_permission" "provisioning_api" {
  statement_id  = "InvokeByAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.provisioning.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_stage.api.execution_arn}/*"
}

resource "aws_iam_role" "claiming" {
  name = local.claiming_function

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

resource "aws_lambda_function" "claiming" {
  function_name = local.claiming_function
  role          = aws_iam_role.claiming.arn
  handler       = "dist/aws/lambda.claimHandler"

  s3_bucket = local.s3_bucket
  s3_key    = local.s3_code_key

  runtime       = "nodejs14.x"
  architectures = ["arm64"]
  memory_size   = 256

  environment {
    variables = local.function_environment
  }

  depends_on = [
    aws_iam_role_policy_attachment.claiming,
    aws_iam_role_policy_attachment.claiming_logging,
  ]
}

resource "aws_iam_role_policy_attachment" "claiming" {
  role       = aws_iam_role.claiming.name
  policy_arn = aws_iam_policy.claiming.arn
}

resource "aws_iam_role_policy_attachment" "claiming_logging" {
  role       = aws_iam_role.claiming.name
  policy_arn = aws_iam_policy.logging.arn
}

resource "aws_lambda_permission" "claiming_api" {
  statement_id  = "InvokeByAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.claiming.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_stage.api.execution_arn}/*"
}

resource "aws_iam_role" "clients" {
  name = local.clients_function

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

resource "aws_lambda_function" "clients" {
  function_name = local.clients_function
  role          = aws_iam_role.clients.arn
  handler       = "dist/aws/lambda.clientsHandler"

  s3_bucket = local.s3_bucket
  s3_key    = local.s3_code_key

  runtime       = "nodejs14.x"
  architectures = ["arm64"]
  memory_size   = 256

  environment {
    variables = local.function_environment
  }

  depends_on = [
    aws_iam_role_policy_attachment.clients,
    aws_iam_role_policy_attachment.clients_logging,
  ]
}

resource "aws_iam_role_policy_attachment" "clients" {
  role       = aws_iam_role.clients.name
  policy_arn = aws_iam_policy.clients.arn
}

resource "aws_iam_role_policy_attachment" "clients_logging" {
  role       = aws_iam_role.clients.name
  policy_arn = aws_iam_policy.logging.arn
}

resource "aws_lambda_permission" "clients_api" {
  statement_id  = "InvokeByAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.clients.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_stage.api.execution_arn}/*"
}
