resource "aws_ssm_parameter" "root_provisioner_name" {
  name        = "/${var.ssm_parameter_prefix}/provisioners/root/name"
  description = "Root Provisioner"
  type        = "String"
  value       = "Root Provisioner"
}

resource "random_password" "root_provisioner_password" {
  length  = 20
  special = false
}

resource "aws_ssm_parameter" "root_provisioner_password" {
  name        = "/${var.ssm_parameter_prefix}/provisioners/root/passwords/initial"
  description = "Initial Root Provisioner password"
  type        = "SecureString"
  value       = random_password.root_provisioner_password.result
}

resource "aws_ssm_parameter" "network_server_name" {
  for_each    = var.network_servers
  name        = "/${var.ssm_parameter_prefix}/networkservers/${each.key}/name"
  description = "Name of ${each.key}"
  type        = "String"
  value       = var.network_servers[each.key].name
}

resource "random_password" "network_server_password" {
  for_each = var.network_servers
  length   = 20
  special  = false
}

resource "aws_ssm_parameter" "network_server_password" {
  for_each = var.network_servers

  name        = "/${var.ssm_parameter_prefix}/networkservers/${each.key}/password/initial"
  description = "Initial Network Server password of ${each.value.name}"
  type        = "SecureString"
  value       = random_password.network_server_password[each.key].result
}

resource "aws_ssm_parameter" "application_server_name" {
  for_each    = var.application_servers
  name        = "/${var.ssm_parameter_prefix}/applicationservers/${each.key}/name"
  description = "Name of ${each.key}"
  type        = "String"
  value       = each.value.name
}

resource "random_password" "application_server_password" {
  for_each = var.application_servers
  length   = 20
  special  = false
}

resource "aws_ssm_parameter" "application_server_password" {
  for_each    = var.application_servers
  name        = "/${var.ssm_parameter_prefix}/applicationservers/${each.key}/passwords/initial"
  description = "Initial Application Server password with ${each.value.name}"
  type        = "SecureString"
  value       = random_password.application_server_password[each.key].result
}
