/* Declare Variables */
variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR Block for the VPC"
  type        = string
}

variable "azs" {
  description = "Availability Zones"
  type        = list(string)
}

variable "public_subnets" {
  description = "Public Subnet CIDRs"
  type        = list(string)
}

variable "private_subnets" {
  description = "Private Subnet CIDRs"
  type        = list(string)
}

variable "data_subnets" {
  description = "Private Data Subnet CIDRs"
  type        = list(string)
}
