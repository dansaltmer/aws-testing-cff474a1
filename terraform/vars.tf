variable "project_name" {
  type        = string
  description = "name of the project to be prefixed onto resources and tagged"
}

variable "vpn_client_provider_arn" {
  type        = string
  description = "arn of the vpn client"
}

variable "vpn_selfserve_provider_arn" {
  type        = string
  description = "arn of the vpn self service portal"
}

variable "domain_zone_name" {
  type        = string
  description = "name of the route53 zone"
}

variable "domain_name" {
  type        = string
  description = "domain to host the gateway on"
}
