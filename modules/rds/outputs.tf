output "db_instance_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = var.create_rds > 0 ? aws_db_instance.main[0].endpoint : null
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = var.create_rds > 0 ? aws_db_instance.main[0].arn : null
}

output "db_secret_arn" {
  description = "The ARN of the secret containing the database credentials"
  value       = var.create_rds > 0 ? aws_secretsmanager_secret.db_credentials[0].arn : null
}
