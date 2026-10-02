
##########################
# ECS Cluster
##########################

resource "aws_ecs_cluster" "ecs" {
  name = "${local.name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = local.common_tags
}


##########################
# Frontend Task Definition
##########################

resource "aws_ecs_task_definition" "frontend" {
  family                   = "${local.name}-frontend"
  # 'FARGATE' : AWS runs the underlying servers
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = tostring(var.frontend_cpu)
  memory = tostring(var.frontend_memory)

  execution_role_arn = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([
    {
      name      = "frontend"

      # Placeholder image used when Terraform creates the initial ECS task definition.
      # GitHub Actions replaces this image with the versioned ECR image
      # (using the Git commit SHA) during the CI/CD deployment.
      image = "PLACEHOLDER"

      essential = true

      portMappings = [
        {
          name          = "frontend"
          containerPort = var.frontend_container_port
          hostPort      = var.frontend_container_port
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]

      healthCheck = {
        command = [
          "CMD-SHELL",
          "wget -q -O /dev/null http://127.0.0.1/ || exit 1"
        ]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.frontend.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "frontend"
        }
      }
    }
  ])

  tags = local.common_tags
}

##########################
# Backend Task Definition ( Container blueprint )
##########################

resource "aws_ecs_task_definition" "backend" {
  family                   = "${local.name}-backend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = tostring(var.backend_cpu)
  memory = tostring(var.backend_memory)

  execution_role_arn = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      
      # Placeholder image used when Terraform creates the initial ECS task definition.
      # GitHub Actions replaces this image with the versioned ECR image
      # (using the Git commit SHA) during the CI/CD deployment.
      image = "PLACEHOLDER"
      
      essential = true

      portMappings = [
        {
          name          = "backend"
          containerPort = var.backend_container_port
          hostPort      = var.backend_container_port
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]

      environment = [
        {
          name  = "DB_HOST"
          value = aws_db_instance.postgresdb.address
        },
        {
          name  = "DB_PORT"
          value = tostring(var.db_port)
        },
        {
          name  = "DB_NAME"
          value = var.db_name
        },
        {
          name  = "DB_USER"
          value = var.db_username
        }
      ]

      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = aws_secretsmanager_secret.postgresdb.arn
        }
      ]

      healthCheck = {
        command = [
          "CMD-SHELL",
          "python -c \"import urllib.request; urllib.request.urlopen('http://127.0.0.1:${var.backend_container_port}/health', timeout=3)\" || exit 1"
        ]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 30
      }

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.backend.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "backend"
        }
      }
    }
  ])

  tags = local.common_tags
}

##########################
# Frontend ECS Service
##########################

resource "aws_ecs_service" "frontend" {
  name            = "${local.name}-frontend"
  cluster         = aws_ecs_cluster.ecs.id
  task_definition = aws_ecs_task_definition.frontend.arn

  desired_count = var.frontend_desired_count
  launch_type   = "FARGATE"

  platform_version = "LATEST"

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  health_check_grace_period_seconds = 60

  network_configuration {
    subnets          = module.network.private_subnet_ids
    security_groups  = [module.security.frontend_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = var.frontend_container_port
  }

  depends_on = [
    aws_lb_listener.http
  ]

  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count
    ]
  }

  tags = local.common_tags
}

##########################
# Backend ECS Service
##########################

resource "aws_ecs_service" "backend" {
  name            = "${local.name}-backend"
  cluster         = aws_ecs_cluster.ecs.id
  task_definition = aws_ecs_task_definition.backend.arn

  desired_count = var.backend_desired_count
  launch_type   = "FARGATE"

  platform_version = "LATEST"

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  health_check_grace_period_seconds = 90

  network_configuration {
    subnets          = module.network.private_subnet_ids
    security_groups  = [module.security.backend_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = var.backend_container_port
  }

  depends_on = [
    aws_lb_listener.http,
    aws_iam_role_policy.ecs_execution_secrets
  ]

  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count
    ]
  }

  tags = local.common_tags
}