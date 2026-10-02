#############
# AWS
#############

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


#############
# Network
#############

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

variable "tags" {
  default     = {}
}


#############
# ECR ( Won't be needed as GitHubActions will mange images tagging during CI/CD )
#############

# variable "backend_image_version" {
#   type    = string
#   default = "v1"
# }

# variable "frontend_image_version" {
#   type    = string
#   default = "v1"
# }


#############
# Github
#############

variable "github_branch" {
  type    = string
  default = "main"
}

variable "github_repository" {
  type    = string
  default = "NaghamMohamedMohamed/Electro-Pi-Task"
}


#############
# ECS
#############

variable "frontend_container_port" {
  type    = number
  default = 80
}

variable "backend_container_port" {
  type    = number
  default = 8000
}

variable "frontend_cpu" {
  type    = number
  default = 256
}

variable "frontend_memory" {
  type    = number
  default = 512
}

variable "backend_cpu" {
  type    = number
  default = 256
}

variable "backend_memory" {
  type    = number
  default = 512
}

variable "frontend_desired_count" {
  type    = number
  default = 0
}

variable "backend_desired_count" {
  type    = number
  default = 0
}

variable "log_retention_days" {
  type    = number
  default = 14
}

# #############
# RDS
# #############

variable "postgres_engine_version" {
  type        = string
  description = "Supported PostgreSQL engine version in the chosen AWS region."
  default = "16.4"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_max_allocated_storage" {
  type    = number
  default = 50
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
  sensitive   = true
}

variable "db_port" {
  description = "PostgreSQL port"
  type        = number
  default     = 5432
}


variable "db_multi_az" {
  type    = bool
  default = false
}


# #############
# Secrets
# #############

variable "secret_recovery_window_days" {
  description = "Number of days before a deleted Secrets Manager secret is permanently deleted"
  type        = number
  default     = 7
}



# #############
# # Monitoring
# #############

variable "alb_5xx_threshold" {
  type    = number
  default = 5
}