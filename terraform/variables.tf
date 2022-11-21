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
  default = "2.0.0-rc.2"
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

variable "provisioners" {
  type = map(object({
    name = string
  }))
  default = {
    "root" = {
      name = "root"
    }
  }
  validation {
    condition = alltrue(
      [for as_id, app in var.provisioners : can(regex("^[0-9a-zA-Z\\.-]+$", as_id))],
    )
    error_message = "Provisioner ID may only contain alphanumeric characters, dots, underscores and dashes."
  }
}

variable "network_servers" {
  type = map(object({
    name = string
  }))
  default = {}
  validation {
    condition = alltrue(
      [for id, network in var.network_servers : can(regex("^[0-9A-F]{6}(\\/[0-9A-F]{16})?$", id))],
    )
    error_message = "The key must be a NetID (6 hex digits) with optional NSID (16 hex digits) separated by forward slash."
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
