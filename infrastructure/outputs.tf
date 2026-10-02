# Output the ARN of the master database password so it can be referenced by the ECS task definition and IAM policies.

output "rds_master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret managed by RDS"
  value       = aws_db_instance.postgresdb.master_user_secret[0].secret_arn
}

############################
# GitHub Actions Outputs
############################

output "aws_region" {
  description = "AWS region used by the deployment"
  value       = var.aws_region
}

output "aws_role_arn" {
  description = "IAM role assumed by GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}

output "ecr_frontend_repository" {
  description = "Frontend ECR repository URL"
  value       = aws_ecr_repository.frontend.repository_url
}

output "ecr_backtend_repository" {
  description = "Backend ECR repository URL"
  value       = aws_ecr_repository.backend.repository_url
}

output "ecs_cluster" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.ecs.name
}

output "ecs_frontend_service" {
  description = "Frontend ECS service name"
  value       = aws_ecs_service.frontend.name
}

output "ecs_backend_service" {
  description = "Backend ECS service name"
  value       = aws_ecs_service.backend.name
}

output "ecs_frontend_task_family" {
  description = "Frontend ECS task definition family"
  value       = aws_ecs_task_definition.frontend.family
}

output "ecs_backend_task_family" {
  description = "Backend ECS task definition family"
  value       = aws_ecs_task_definition.backend.family
}

output "alb_url" {
  description = "Application Load Balancer URL"
  value       = "http://${aws_lb.alb.dns_name}"
}
