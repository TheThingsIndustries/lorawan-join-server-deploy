variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "public_url" {
  type    = string
  default = ""
}

variable "source_s3_bucket_prefix" {
  type    = string
  default = "thethingsindustries"
}

variable "release_channel" {
  type    = string
  default = "stable"
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
  default = "lorawan/joinserver/v1"
}

variable "iot_thing_type" {
  type    = string
  default = "lorawan-join-server"
}

variable "networks" {
  type = map(object({
    name = string
    kek = object({
      label = string
      key   = string
    })
    passwords = map(string)
  }))
  default = {}
  validation {
    condition = alltrue(flatten([
      [for net_id, network in var.networks : can(regex("^[0-9A-F]{6}|[0-9A-F]{16}$", net_id))],
      [for network in var.networks : can(regex("^[0-9A-F]{32}|$", network.kek.key))]
    ]))
    error_message = "The key must be a NetID (6 hex digits) or NSID (16 hex digits). The KEK key must be a 32 hex digits string."
  }
}

variable "applications" {
  type = map(object({
    name = string
    kek = object({
      label = string
      key   = string
    })
    passwords = map(string)
  }))
  default = {}
  validation {
    condition = alltrue(flatten([
      [for as_id, app in var.applications : can(regex("^[0-9a-zA-Z\\.-]+$", as_id))],
      [for app in var.applications : can(regex("^[0-9A-F]{32}|$", app.kek.key))],
    ]))
    error_message = "AS-ID may only contain alphanumeric characters, dots, underscores and dashes. The KEK key must be a 32 hex digits string."
  }
}
