variable "aws_region" {
  description = "AWS region for the infrastructure"
  type        = string
  default     = "us-west-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "eks-shared-infra"
}

# --- VPC Variables ---
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.30.0.0/16"
}

variable "availability_zones" {
  description = "List of Availability Zones"
  type        = list(string)
  default     = ["us-west-1a", "us-west-1c"]
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.30.1.0/24", "10.30.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.30.101.0/24", "10.30.102.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "enable_nat_instance" {
  description = "Enable NAT Instance instead of NAT Gateway"
  type        = bool
  default     = false
}

# --- RDS Variables ---
variable "create_rds" {
  description = "Whether to create RDS instance (0 or 1)"
  type        = number
  default     = 1
}

variable "rds_database_name" {
  description = "The name of the RDS database"
  type        = string
  default     = "webappdb"
}

variable "rds_instance_class" {
  description = "The instance class for the RDS database"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "The allocated storage for the RDS database in GB"
  type        = number
  default     = 20
}

variable "rds_engine_version" {
  description = "The engine version for the MySQL RDS database"
  type        = string
  default     = "8.0.43"
}
