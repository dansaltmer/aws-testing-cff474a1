variable "vpc_cidr" {
  description = "cidr range for the full vpc"
  type        = string
}

variable "vpn_subnet_cidr" {
  description = "cidr range for the vpn gateway subnet"
  type        = string
}

variable "vpn_client_cidr" {
  description = "cidr range for the clients"
  type        = string
}

variable "vpn_client_provider_arn" {
  description = "arn of the auth provider"
  type        = string
}

variable "vpn_selfserve_provider_arn" {
  description = "arn of the self serve provider"
  type        = string
}

variable "tags" {
  description = "tags to add to resources, name will be suffixed"
  type        = map(string)
}
