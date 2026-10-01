
variable "name" {
  description = "Prefix used to name security groups."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where security groups will be created."
  type        = string
}

variable "alb_ingress_cidrs" {
  description = "CIDR ranges allowed to access the Application Load Balancer."
  type        = list(string)
}

variable "frontend_port" {
  description = "Port used by the frontend container."
  type        = number
}

variable "backend_port" {
  description = "Port used by the FastAPI backend."
  type        = number
}

variable "db_port" {
  description = "Port used by the PostgreSQL database."
  type        = number
}

variable "tags" {
  description = "Tags to apply to all security groups."
  type        = map(string)
  default     = {}
}