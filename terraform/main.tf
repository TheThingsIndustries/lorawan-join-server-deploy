locals {
  s3_bucket   = "${var.source_s3_bucket_prefix}-${var.region}"
  s3_code_key = "lorawan-join-server/${var.release_version}.zip"

  openapi_function           = "${var.resource_prefix}-openapi"
  authorizer_function        = "${var.resource_prefix}-authorizer"
  backendinterfaces_function = "${var.resource_prefix}-bi"
  provisioning_function      = "${var.resource_prefix}-provisioning"
  claiming_function          = "${var.resource_prefix}-claiming"

  public_url = var.domain == "" ? trimsuffix(aws_apigatewayv2_stage.api.invoke_url, "/") : "https://${var.domain}"

  function_environment = {
    JS_SSM_PARAMETER_PREFIX    = "/${var.ssm_parameter_prefix}"
    JS_KMS_KEY_ID              = aws_kms_key.key.id
    JS_DYNAMODB_TABLE_APPSKEYS = aws_dynamodb_table.app_s_keys.id
    JS_DYNAMODB_TABLE_DEVICES  = aws_dynamodb_table.end_devices.id
    JS_PUBLIC_URL              = local.public_url
  }
}

resource "aws_kms_key" "key" {
  description             = "LoRaWAN Join Server"
  deletion_window_in_days = 30
  policy                  = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Enable IAM policies to administer the key",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": [
        "kms:Create*",
        "kms:Describe*",
        "kms:Enable*",
        "kms:List*",
        "kms:Put*",
        "kms:Update*",
        "kms:Revoke*",
        "kms:Disable*",
        "kms:Get*",
        "kms:Delete*",
        "kms:TagResource",
        "kms:UntagResource",
        "kms:ScheduleKeyDeletion",
        "kms:CancelKeyDeletion"
      ],
      "Resource": "*"
    },
    {
      "Sid": "Allow use of the key",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "${aws_iam_role.authorizer.arn}",
          "${aws_iam_role.backendinterfaces.arn}",
          "${aws_iam_role.provisioning.arn}",
          "${aws_iam_role.claiming.arn}"
        ]
      },
      "Action": [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "Allow attachment of persistent resources",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "${aws_iam_role.authorizer.arn}",
          "${aws_iam_role.backendinterfaces.arn}",
          "${aws_iam_role.provisioning.arn}",
          "${aws_iam_role.claiming.arn}"
        ]
      },
      "Action": [
        "kms:CreateGrant",
        "kms:ListGrants",
        "kms:RevokeGrant"
      ],
      "Resource": "*",
      "Condition": {"Bool": {"kms:GrantIsForAWSResource": true}}
    }
  ]
}
EOF
}

resource "aws_kms_alias" "key" {
  name_prefix   = var.kms_alias_name_prefix
  target_key_id = aws_kms_key.key.key_id
}

resource "aws_dynamodb_table" "app_s_keys" {
  name         = "${var.resource_prefix}-appskeys"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "ASIDDevEUI"
  range_key    = "SessionKeyID"
  attribute {
    name = "ASIDDevEUI"
    type = "S"
  }
  attribute {
    name = "SessionKeyID"
    type = "S"
  }
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.key.arn
  }
  table_class = "STANDARD_INFREQUENT_ACCESS"
}

resource "aws_dynamodb_table" "end_devices" {
  name         = "${var.resource_prefix}-devices"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "DevEUI"
  attribute {
    name = "DevEUI"
    type = "S"
  }
  attribute {
    name = "ProvisionerID"
    type = "S"
  }
  global_secondary_index {
    hash_key        = "ProvisionerID"
    name            = "ProvisionerIDIndex"
    projection_type = "ALL"
  }
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.key.arn
  }
  table_class = "STANDARD"
}
