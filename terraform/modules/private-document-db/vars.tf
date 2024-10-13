variable "vpc_id" {
  description = "vpc id to add a subnet into"
  type        = string
}

variable "subnet_cidrs" {
  description = "cidr range of the subnet to create the document db in"
  type        = list(string)
  validation {
    condition     = (length(var.subnet_cidrs) == 2)
    error_message = "must have a length of 2"
  }
}

variable "tags" {
  description = "tags to add to resources, name will be suffixed"
  type        = map(string)
}
