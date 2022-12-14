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

resource "aws_ssm_parameter" "network_server_truststore" {
  for_each    = var.network_servers
  name        = "/${var.ssm_parameter_prefix}/truststores/${each.key}"
  description = "Trust store of Network Server ${each.key}"
  type        = "String"
  value       = file(var.network_servers[each.key].truststore)
}

resource "aws_ssm_parameter" "application_server_truststore" {
  for_each    = var.application_servers
  name        = "/${var.ssm_parameter_prefix}/truststores/${each.key}"
  description = "Trust store of Application Server ${each.key}"
  type        = "String"
  value       = file(var.application_servers[each.key].truststore)
}
