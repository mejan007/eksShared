# locals {
#   # Derived Flags
#   has_public_subnets  = var.public_subnet_count > 0
#   has_private_subnets = var.private_subnet_count > 0
#   enable_igw         = var.enable_igw && local.has_public_subnets
#   enable_nat         = (var.enable_nat_gateway || var.enable_nat_instance) && local.has_private_subnets && local.has_public_subnets

#   # Unique AZs for public and private subnets
#   private_subnet_azs = distinct([for i in range(var.private_subnet_count) : var.availability_zones[i % length(var.availability_zones)]])
#   public_subnet_azs  = distinct([for i in range(var.public_subnet_count) : var.availability_zones[i % length(var.availability_zones)]])

#   # NAT Count: One per private subnet AZ, capped by public subnet AZs
#   nat_count = local.enable_nat ? min(length(local.private_subnet_azs), length(local.public_subnet_azs)) : 0

#   # Naming Conventions
#   vpc_name_prefix = "${var.vpc_name}-"
#   tags = {
#     Environment = var.vpc_name
#     ManagedBy   = "Terraform"
#   }

#   # Subnet Maps for for_each (round-robin for extra subnets)
#   public_subnet_map = {
#     for i in range(var.public_subnet_count) :
#     "${i}-${var.availability_zones[i % length(var.availability_zones)]}" => {
#       cidr = var.public_subnet_cidrs[i]
#       az   = var.availability_zones[i % length(var.availability_zones)]
#     }
#   }
#   private_subnet_map = {
#     for i in range(var.private_subnet_count) :
#     "${i}-${var.availability_zones[i % length(var.availability_zones)]}" => {
#       cidr = var.private_subnet_cidrs[i]
#       az   = var.availability_zones[i % length(var.availability_zones)]
#     }
#   }

#   # Private Route Table: One per private subnet AZ
#   private_rt_map = local.has_private_subnets ? { for az in local.private_subnet_azs : az => az } : {}
# }

# Explanation of maps:

/*

module "vpc" {
  source = "./modules/vpc"
  public_subnets = [
    { cidr = "10.0.1.0/24", az = "us-east-1a" },
    { cidr = "10.0.2.0/24", az = "us-east-1b" },
    { cidr = "10.0.3.0/24", az = "us-east-1a" }
  ]
}

Here, var.public_subnets is a list of three objects:

Index 0: { cidr = "10.0.1.0/24", az = "us-east-1a" }
Index 1: { cidr = "10.0.2.0/24", az = "us-east-1b" }
Index 2: { cidr = "10.0.3.0/24", az = "us-east-1a" }


Map requires unique keys, so we create keys by combining the index and the AZ:

public_subnet_map = {
  "0-us-east-1a" = { cidr = "10.0.1.0/24", az = "us-east-1a" }
  "1-us-east-1b" = { cidr = "10.0.2.0/24", az = "us-east-1b" }
  "2-us-east-1a" = { cidr = "10.0.3.0/24", az = "us-east-1a" }
}
*/


locals {
  has_public_subnets  = length(var.public_subnet_cidrs) > 0
  has_private_subnets = length(var.private_subnet_cidrs) > 0
  # enable_igw         = var.enable_igw && local.has_public_subnets
  enable_nat = (var.enable_nat_gateway || var.enable_nat_instance) && local.has_private_subnets && local.has_public_subnets
}