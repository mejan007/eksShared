# --- VPC Outputs ---
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "Map of AZ to public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Map of AZ to private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "availability_zones" {
  description = "List of availability zones"
  value       = module.vpc.availability_zones
}

# --- RDS Outputs ---
output "rds_instance_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = var.create_rds > 0 ? module.rds_mysql[0].db_instance_endpoint : "RDS not deployed"
}

output "database_secret_arn" {
  description = "ARN of the Secrets Manager secret for the database"
  value       = var.create_rds > 0 ? module.rds_mysql[0].db_secret_arn : "RDS not deployed"
}
