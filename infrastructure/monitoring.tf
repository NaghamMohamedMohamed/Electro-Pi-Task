##########################
# CloudWatch Log Groups
##########################

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${local.name}/frontend"
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${local.name}/backend"
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}


##########################
# ALB HTTP 5xx Alarm
##########################

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name        = "${local.name}-alb-5xx"
  alarm_description = "ALB is returning HTTP 5xx errors"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_ELB_5XX_Count"

  statistic = "Sum"
  period    = 60

  evaluation_periods  = 2
  datapoints_to_alarm = 2

  threshold           = var.alb_5xx_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"

  dimensions = {
    LoadBalancer = aws_lb.alb.arn_suffix
  }

  treat_missing_data = "notBreaching"

  tags = local.common_tags
}