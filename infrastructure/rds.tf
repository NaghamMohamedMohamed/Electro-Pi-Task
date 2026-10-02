##########################
# RDS DB Subnet Group 
# ( specifies which subnets/AZs the RDS PostgreSQL instance can use.)
##########################

resource "aws_db_subnet_group" "db_subnet_group" {
  name        = "${local.name}-db-subnets"
  description = "Private database subnet group for ${local.name}"

  subnet_ids = module.network.db_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.name}-db-subnets"
  })
}

##########################
# RDS PostgreSQL Instance
##########################

resource "aws_db_instance" "postgresdb" {
    identifier = "${local.name}-postgres"

    # PostgreSQL
    engine         = "postgres"
    engine_version = var.postgres_engine_version
    instance_class = var.db_instance_class

    # Storage
    allocated_storage     = var.db_allocated_storage
    max_allocated_storage = var.db_max_allocated_storage
    storage_type          = "gp3"
    storage_encrypted     = true

    # Database
    db_name  = var.db_name
    username = var.db_username
    port  = var.db_port

    # RDS generate and manage the master passwor in AWS Secrets Manager.
    manage_master_user_password = true

    # Networking
    db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
    vpc_security_group_ids = [module.security.database_security_group_id]

    publicly_accessible = false
    multi_az            = var.db_multi_az

    # Backups disabled
    backup_retention_period = 0

    # Updates
    auto_minor_version_upgrade = false
    apply_immediately           = false

    # Deletion
    deletion_protection = false
    skip_final_snapshot = true

    # CloudWatch logs
    enabled_cloudwatch_logs_exports = [
        "postgresql",
        "upgrade"
    ]

    tags = merge(local.common_tags, {
        Name = "${local.name}-postgres"
        Tier = "database"
    })

}