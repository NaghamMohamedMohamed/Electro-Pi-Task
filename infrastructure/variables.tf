variable "aws_region" {

  type    = string
  default = "us-east-1"
}

variable "project" {

  type    = string
  default = "three-tier"
}

variable "environment" {

  type    = string
  default = "dev"
}

variable "availability_zones" {

  type = list(string)

  default = [ "us-east-1a", "us-east-1b"]
}

variable "vpc_cidr" {

  type    = string
  default = "10.20.0.0/16"
}

# Host the internet-facing Application Load Balancer (ALB)
variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.0.0/24", "10.20.1.0/24"]
}

# Host frontend and backend ECS containers
variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.10.0/24", "10.20.11.0/24"]
}

# Used by RDS, with no direct public access.
variable "db_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.20.0/24", "10.20.21.0/24"]
}


variable "alb_ingress_cidrs" {
  default     = ["0.0.0.0/0"]
}

variable "frontend_port" {
  default     = 80
}

variable "backend_port" {
  default     = 8000
}

variable "db_port" {
  default     = 5432
}

variable "tags" {
  default     = {}
}

variable "backend_image_version" {
  type    = string
  default = "v1"
}

variable "frontend_image_version" {
  type    = string
  default = "v1"
}
