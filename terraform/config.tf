resource "aws_ssm_parameter" "provisioner_name" {
  for_each    = var.provisioners
  name        = "/${var.ssm_parameter_prefix}/provisioners/${each.key}/name"
  description = "Name of ${each.key}"
  type        = "String"
  value       = var.provisioners[each.key].name
}

resource "random_password" "provisioner_password" {
  for_each = var.provisioners
  length   = 20
  special  = false
}

resource "aws_ssm_parameter" "provisioner_password" {
  for_each = var.provisioners

  name        = "/${var.ssm_parameter_prefix}/provisioners/${each.key}/passwords/initial"
  description = "Initial Provisioner password of ${each.value.name}"
  type        = "SecureString"
  value       = random_password.provisioner_password[each.key].result
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

  name        = "/${var.ssm_parameter_prefix}/networkservers/${each.key}/passwords/initial"
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
