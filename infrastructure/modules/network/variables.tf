variable "name" {
  description = "Prefix used to name network resources."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "availability_zones" {
  description = "Availability zones where subnets will be created."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per availability zone."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private application subnets, one per availability zone."
  type        = list(string)
}

variable "db_subnet_cidrs" {
  description = "CIDR blocks for private database subnets, one per availability zone."
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to network resources."
  type        = map(string)
  default     = {}
}