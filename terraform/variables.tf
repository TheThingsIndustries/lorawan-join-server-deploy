variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "domain" {
  type    = string
  default = ""
}

variable "source_s3_bucket_prefix" {
  type    = string
  default = "thethingsindustries"
}

variable "release_version" {
  type    = string
  default = "2.0.0-rc.1"
}

variable "kms_alias_name_prefix" {
  type    = string
  default = "alias/lorawan-join-server"
}

variable "resource_prefix" {
  type    = string
  default = "lorawan-join-server"
}

variable "ssm_parameter_prefix" {
  type    = string
  default = "lorawan/joinserver/v2"
}

variable "network_servers" {
  type = map(object({
    name = string
  }))
  default = {}
  validation {
    condition = alltrue(
      [for net_id, network in var.network_servers : can(regex("^[0-9A-F]{6}|[0-9A-F]{16}$", net_id))],
    )
    error_message = "The key must be a NetID (6 hex digits) or NSID (16 hex digits)."
  }
}

variable "application_servers" {
  type = map(object({
    name = string
  }))
  default = {}
  validation {
    condition = alltrue(
      [for as_id, app in var.application_servers : can(regex("^[0-9a-zA-Z\\.-]+$", as_id))],
    )
    error_message = "AS-ID may only contain alphanumeric characters, dots, underscores and dashes."
  }
}
