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

resource "aws_ssm_parameter" "network_name" {
  for_each = toset([for net_id, network in var.networks : net_id])

  name        = "/${var.ssm_parameter_prefix}/networks/${each.key}/name"
  description = "Name of ${each.key}"
  type        = "String"
  value       = var.networks[each.key].name
}

resource "aws_ssm_parameter" "network_kek_label" {
  for_each = { for network_id, network in var.networks : network_id => network_id if var.networks[network_id].kek.label != "" }

  name        = "/${var.ssm_parameter_prefix}/networks/${each.key}/kek/label"
  description = "Key encryption key label ${var.networks[each.key].kek.label}"
  type        = "String"
  value       = var.networks[each.key].kek.label
}

resource "aws_ssm_parameter" "network_kek_key" {
  for_each = { for network_id, network in var.networks : network_id => network_id if var.networks[network_id].kek.label != "" }

  name            = "/${var.ssm_parameter_prefix}/networks/${each.key}/kek/key"
  description     = "Key encryption key with ${var.networks[each.key].kek.label}"
  type            = "SecureString"
  allowed_pattern = "[0-9A-F]{32}"
  value           = var.networks[each.key].kek.key
}

resource "aws_ssm_parameter" "network_passwords" {
  for_each = {
    for network in flatten([
      for network_id, network in var.networks : [
        for password_key, password in network.passwords : {
          network_id   = network_id
          password_key = password_key
        }
      ]
    ]) : "${network.network_id}/${network.password_key}" => network
  }

  name        = "/${var.ssm_parameter_prefix}/networks/${each.value.network_id}/passwords/${each.value.password_key}"
  description = "Network Server password with ${each.value.password_key}"
  type        = "SecureString"
  value       = var.networks[each.value.network_id].passwords[each.value.password_key]
}

resource "aws_ssm_parameter" "application_name" {
  for_each = toset([for as_id, application in var.applications : as_id])

  name        = "/${var.ssm_parameter_prefix}/applications/${each.key}/name"
  description = "Name of ${each.key}"
  type        = "String"
  value       = var.applications[each.key].name
}

resource "aws_ssm_parameter" "application_kek_label" {
  for_each = toset([for as_id, application in var.applications : as_id if var.applications[as_id].kek.label != ""])

  name        = "/${var.ssm_parameter_prefix}/applications/${each.key}/kek/label"
  description = "Key encryption key label ${var.applications[each.key].kek.label}"
  type        = "String"
  value       = var.applications[each.key].kek.label
}

resource "aws_ssm_parameter" "application_kek_key" {
  for_each = toset([for as_id, application in var.applications : as_id if var.applications[as_id].kek.label != ""])

  name            = "/${var.ssm_parameter_prefix}/applications/${each.key}/kek/key"
  description     = "Key encryption key with ${var.applications[each.key].kek.label}"
  type            = "SecureString"
  allowed_pattern = "[0-9A-F]{32}"
  value           = var.applications[each.key].kek.key
}

resource "aws_ssm_parameter" "application_passwords" {
  for_each = {
    for app in flatten([
      for as_id, app in var.applications : [
        for password_key, password in app.passwords : {
          as_id        = as_id
          password_key = password_key
        }
      ]
    ]) : "${app.as_id}/${app.password_key}" => app
  }

  name        = "/${var.ssm_parameter_prefix}/applications/${each.value.as_id}/passwords/${each.value.password_key}"
  description = "Application Server password with ${each.value.password_key}"
  type        = "SecureString"
  value       = var.applications[each.value.as_id].passwords[each.value.password_key]
}
