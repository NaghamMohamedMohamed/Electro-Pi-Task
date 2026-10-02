##########################
# Database Secret
##########################

resource "aws_secretsmanager_secret" "postgresdb" {
  name                    = "${local.name}/postgresdb"
  description             = "PostgreSQL connection details for ${local.name}"
  recovery_window_in_days = var.secret_recovery_window_days

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.postgresdb.id

  secret_string = jsonencode({
    DB_NAME     = var.db_name
    DB_USER     = var.db_username
    DB_PORT     = var.db_port
    DB_HOST     = aws_db_instance.postgresdb.address
  })
}