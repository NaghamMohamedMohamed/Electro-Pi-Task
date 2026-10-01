
output "alb_security_group_id" {
  description = "Security group ID for the Application Load Balancer."
  value       = aws_security_group.alb.id
}

output "frontend_security_group_id" {
  description = "Security group ID for the frontend ECS service."
  value       = aws_security_group.frontend.id
}

output "backend_security_group_id" {
  description = "Security group ID for the backend ECS service."
  value       = aws_security_group.backend.id
}

output "database_security_group_id" {
  description = "Security group ID for the RDS database."
  value       = aws_security_group.database.id
}

output "security_group_ids" {
  description = "Map of security group IDs."
  value = {
    alb      = aws_security_group.alb.id
    frontend = aws_security_group.frontend.id
    backend  = aws_security_group.backend.id
    database = aws_security_group.database.id
  }
}