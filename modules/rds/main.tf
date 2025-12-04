locals {
  name_prefix = "${var.project_name}-${var.environment}"
  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_db_subnet_group" "main" {
  count      = var.create_rds
  name       = "${local.name_prefix}-sng"
  subnet_ids = var.subnet_ids
  tags       = merge(local.tags, { Name = "${local.name_prefix}-sng" })
}

resource "random_password" "db_password" {
  count            = var.create_rds
  length           = 16
  special          = true
  override_special = "!#$%&'()*+,-.:;<=>?[]^_`{|}~"
}

resource "aws_secretsmanager_secret" "db_credentials" {
  count = var.create_rds
  name  = "${local.name_prefix}-db-credential"
  tags  = local.tags
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  count     = var.create_rds
  secret_id = aws_secretsmanager_secret.db_credentials[0].id
  secret_string = jsonencode({
    username = var.db_username,
    password = random_password.db_password[0].result
  })
}

resource "aws_db_instance" "main" {
  count                        = var.create_rds
  identifier                   = "${local.name_prefix}-db"
  engine                       = var.engine
  engine_version               = var.engine_version
  instance_class               = var.db_instance_class
  allocated_storage            = var.allocated_storage
  db_name                      = var.db_name
  username                     = jsondecode(aws_secretsmanager_secret_version.db_credentials[0].secret_string).username
  password                     = jsondecode(aws_secretsmanager_secret_version.db_credentials[0].secret_string).password
  db_subnet_group_name         = aws_db_subnet_group.main[0].name
  vpc_security_group_ids       = [var.security_group_id]
  skip_final_snapshot          = true
  publicly_accessible          = false
  backup_retention_period      = var.backup_retention_period
  tags                         = merge(local.tags, { Name = "${local.name_prefix}-db" })
  delete_automated_backups     = true
  performance_insights_enabled = false
  monitoring_interval          = 0
}
