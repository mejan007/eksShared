variable "create_rds" {
  description = "Whether to create RDS instance (0 or 1)"
  type        = number
  default     = 1
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the RDS instance will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "security_group_id" {
  description = "The ID of the security group to associate with the RDS instance"
  type        = string
}

variable "db_name" {
  description = "The name of the database"
  type        = string
}

variable "db_username" {
  description = "The master username for the database"
  type        = string
  default     = "postgresadmin"
}

variable "db_instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
}

variable "allocated_storage" {
  description = "The allocated storage in gigabytes"
  type        = number
}
variable "engine" {
  description = "The database engine to use"
  type        = string

}
variable "engine_version" {
  description = "The PostgreSQL engine version"
  type        = string
}

variable "backup_retention_period" {
  description = "The number of days to retain backups for. 0 disables automated backups"
  type        = number
  default     = 0
}
