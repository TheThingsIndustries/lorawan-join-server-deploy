data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_name
}

locals {
  eks_oidc_provider_url = trimprefix(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://")
  eks_oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.eks_oidc_provider_url}"
}

data "aws_iam_policy_document" "server_policy" {
  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem"
    ]
    resources = [
      "arn:aws:dynamodb:*:*:table/${aws_dynamodb_table.app_s_keys.name}"
    ]
  }
  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Scan"
    ]
    resources = [
      "arn:aws:dynamodb:*:*:table/${aws_dynamodb_table.end_devices.name}"
    ]
  }
  statement {
    actions = [
      "ssm:GetParameter",
      "ssm:GetParametersByPath"
    ]
    resources = [
      "arn:aws:ssm:*:*:parameter/${var.ssm_parameter_prefix}/*"
    ]
  }
}

resource "aws_iam_policy" "server" {
  name   = var.resource_prefix
  policy = data.aws_iam_policy_document.server_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    sid     = "ServiceAccount"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    condition {
      test     = "StringEquals"
      variable = "${local.eks_oidc_provider_url}:sub"
      values   = ["system:serviceaccount:${var.kubernetes_namespace}:ttjs"]
    }
    principals {
      identifiers = [local.eks_oidc_provider_arn]
      type        = "Federated"
    }
  }
  statement {
    sid     = "AdditionalPrincipals"
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      identifiers = var.assume_role_principals
      type        = "AWS"
    }
  }
}

resource "aws_iam_role" "server" {
  name               = var.resource_prefix
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "server" {
  role       = aws_iam_role.server.name
  policy_arn = aws_iam_policy.server.arn
}

data "aws_iam_policy_document" "kms_policy" {
  statement {
    sid    = "Enable IAM policies to administer the key"
    effect = "Allow"
    actions = [
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
    ]
    resources = ["*"]
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      type        = "AWS"
    }
  }
  statement {
    sid    = "Allow use of the key"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*"
    ]
    resources = ["*"]
    principals {
      identifiers = [aws_iam_role.server.arn]
      type        = "AWS"
    }
  }
  statement {
    sid    = "Allow attachment of persistent resources"
    effect = "Allow"
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    resources = ["*"]
    principals {
      identifiers = [aws_iam_role.server.arn]
      type        = "AWS"
    }
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}

resource "aws_kms_key" "key" {
  description             = "The Things Join Server"
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.kms_policy.json
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
