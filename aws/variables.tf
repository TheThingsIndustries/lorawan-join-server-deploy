variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "assume_role_principals" {
  type        = list(string)
  description = "Additional principals (users, roles) that can assume the role"
  default     = []
}

variable "kms_alias_name_prefix" {
  type    = string
  default = "alias/the-things-join-server"
}

variable "resource_prefix" {
  type    = string
  default = "the-things-join-server"
}

variable "ssm_parameter_prefix" {
  type    = string
  default = "the-things-join-server/v2"
}

variable "eks_cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "kubernetes_namespace" {
  type    = string
  default = "default"
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
      [for id, app in var.provisioners : can(regex("^[0-9a-zA-Z\\.-]+$", id))],
    )
    error_message = "Provisioner ID may only contain alphanumeric characters, dots, underscores and dashes."
  }
}

variable "network_servers" {
  type = map(object({
    name       = string
    truststore = string
  }))
  default = {
    "000013" = {
      name       = "The Things Stack Cloud and Community Edition"
      truststore = "truststores/the-things-industries.pem"
    }
  }
  validation {
    condition = alltrue(
      [for id, network in var.network_servers : can(regex("^[0-9A-F]{6}(\\/[0-9A-F]{16})?$", id))],
    )
    error_message = "The key must be a NetID (6 hex digits) with optional NSID (16 hex digits) separated by forward slash."
  }
}

variable "application_servers" {
  type = map(object({
    name       = string
    truststore = string
  }))
  default = {}
  validation {
    condition = alltrue(
      [for as_id, app in var.application_servers : can(regex("^[0-9a-zA-Z\\.-]+$", as_id))],
    )
    error_message = "AS-ID may only contain alphanumeric characters, dots, underscores and dashes."
  }
}
