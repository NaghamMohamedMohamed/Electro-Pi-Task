
##########################
# Application Load Balancer
##########################

resource "aws_lb" "alb" {
  name               = "${local.name}-alb"
  internal           = false
  load_balancer_type = "application"

  subnets         = module.network.public_subnet_ids
  security_groups = [module.security.alb_security_group_id]

  enable_deletion_protection = false

  tags = local.common_tags
}


##########################
# Frontend Target Group ( Defines where the ALB sends frontend traffic )
##########################

resource "aws_lb_target_group" "frontend" {
  name        = "${local.name}-frontend-tg"
  port        = var.frontend_container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.network.vpc_id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = local.common_tags
}


##########################
# Backend Target Group
##########################

resource "aws_lb_target_group" "backend" {
  name        = "${local.name}-backend-tg"
  port        = var.backend_container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.network.vpc_id

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = local.common_tags
}


##########################
# HTTP Listener
##########################

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  tags = local.common_tags
}

##########################
# Backend Path-Based Routing
##########################

resource "aws_lb_listener_rule" "backend" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  condition {
    path_pattern {
      values = [
        "/api/*",
        "/health"
      ]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  tags = local.common_tags
}