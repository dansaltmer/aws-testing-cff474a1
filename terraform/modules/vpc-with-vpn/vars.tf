variable "vpc-cidr" {
  description = "cidr range for the full vpc"
  type        = string
}

variable "vpn-subnet-cidr" {
  description = "cidr range for the vpn gateway subnet"
  type        = string
}

variable "vpn-client-cidr" {
  description = "cidr range for the clients"
  type        = string
}

variable "vpn-client-provider-arn" {
  description = "arn of the auth provider"
  type = string
}

variable "vpn-selfserve-provider-arn" {
  description = "arn of the self serve provider"
  type = string
}

variable "tags" {
  description = "tags to add to resources, name will be suffixed"
  type        = map(string)
}
