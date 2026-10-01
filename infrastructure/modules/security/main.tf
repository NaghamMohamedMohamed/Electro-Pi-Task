resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "Allow approved HTTP traffic to the ALB"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-alb-sg"
  })
}

resource "aws_security_group" "frontend" {
  name        = "${var.name}-frontend-sg"
  description = "Allow traffic from the ALB to the frontend"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-frontend-sg"
  })
}

resource "aws_security_group" "backend" {
  name        = "${var.name}-backend-sg"
  description = "Allow traffic from the ALB to the backend"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-backend-sg"
  })
}

resource "aws_security_group" "database" {
  name        = "${var.name}-database-sg"
  description = "Allow PostgreSQL traffic from the backend only"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-database-sg"
  })
}

# ALB inbound: HTTP from approved CIDR ranges
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each = toset(var.alb_ingress_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP from ${each.value}"
  cidr_ipv4         = each.value
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

# Frontend inbound: only from ALB
resource "aws_vpc_security_group_ingress_rule" "frontend_from_alb" {
  security_group_id            = aws_security_group.frontend.id
  description                  = "Allow frontend traffic from ALB"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.frontend_port
  to_port                      = var.frontend_port
  ip_protocol                  = "tcp"
}

# Backend inbound: only from ALB
resource "aws_vpc_security_group_ingress_rule" "backend_from_alb" {
  security_group_id            = aws_security_group.backend.id
  description                  = "Allow backend traffic from ALB"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.backend_port
  to_port                      = var.backend_port
  ip_protocol                  = "tcp"
}

# Database inbound: only from backend
resource "aws_vpc_security_group_ingress_rule" "database_from_backend" {
  security_group_id            = aws_security_group.database.id
  description                  = "Allow PostgreSQL from backend"
  referenced_security_group_id = aws_security_group.backend.id
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
}

# Outbound rules
# Allow outbound traffic for application dependencies,
# AWS service access, health checks, and database connections.
locals {
  security_groups = {
    alb      = aws_security_group.alb.id
    frontend = aws_security_group.frontend.id
    backend  = aws_security_group.backend.id
    database = aws_security_group.database.id
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_all_ipv4" {
  for_each = local.security_groups

  security_group_id = each.value
  description       = "Allow outbound IPv4 traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}