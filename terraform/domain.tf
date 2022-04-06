resource "aws_acm_certificate" "domain" {
  count             = var.domain == "" ? 0 : 1
  domain_name       = var.domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_domain_name" "domain" {
  count       = var.domain == "" ? 0 : 1
  domain_name = var.domain

  domain_name_configuration {
    certificate_arn = aws_acm_certificate_validation.domain[0].certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "domain" {
  count       = var.domain == "" ? 0 : 1
  api_id      = aws_apigatewayv2_api.api.id
  domain_name = aws_apigatewayv2_domain_name.domain[0].id
  stage       = aws_apigatewayv2_stage.api.id
}

resource "aws_acm_certificate_validation" "domain" {
  count           = var.domain == "" ? 0 : 1
  certificate_arn = aws_acm_certificate.domain[0].arn
}
