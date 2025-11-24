variable "vpc_name" {
  description = "Name tag for the VPC"
  type        = string
  default     = "my-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = []
  validation {
    condition     = length(var.public_subnet_cidrs) == length(var.availability_zones)
    error_message = "Number of public_subnet_cidrs must match availability zones."
  }
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = []
  validation {
    condition     = length(var.private_subnet_cidrs) == length(var.availability_zones)
    error_message = "Number of private_subnet_cidrs must match availability zones."
  }
}

variable "availability_zones" {
  description = "List of Availability Zones"
  type        = list(string)
  default     = []
}

variable "enable_igw" {
  description = "Enable Internet Gateway"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = false
  validation {
    condition     = var.enable_nat_gateway ? length(var.private_subnet_cidrs) > 0 && length(var.public_subnet_cidrs) > 0 : true
    error_message = "NAT Gateway requires private and public subnets."
  }
  validation {
    condition     = var.enable_nat_gateway ? alltrue([for az in [for i, v in var.private_subnet_cidrs : var.availability_zones[i]] : contains([for j, w in var.public_subnet_cidrs : var.availability_zones[j]], az)]) : true
    error_message = "Every private subnet AZ must have a public subnet AZ."
  }
  validation {
    condition     = !(var.enable_nat_gateway && var.enable_nat_instance)
    error_message = "Cannot enable both NAT Gateway and NAT Instance."
  }
}

variable "enable_nat_instance" {
  description = "Enable NAT Instance"
  type        = bool
  default     = false
  validation {
    condition     = var.enable_nat_instance ? length(var.private_subnet_cidrs) > 0 && length(var.public_subnet_cidrs) > 0 : true
    error_message = "NAT Instance requires private and public subnets."
  }
  validation {
    condition     = var.enable_nat_instance ? alltrue([for az in [for i, v in var.private_subnet_cidrs : var.availability_zones[i]] : contains([for j, w in var.public_subnet_cidrs : var.availability_zones[j]], az)]) : true
    error_message = "Every private subnet AZ must have a public subnet AZ."
  }
}

variable "nat_instance_ami" {
  description = "AMI ID for NAT Instance"
  type        = string
  default     = ""
  validation {
    condition     = var.enable_nat_instance ? var.nat_instance_ami != "" : true
    error_message = "nat_instance_ami required when enable_nat_instance is true."
  }
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = ""
}