output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Map of AZ to public subnet IDs"
  value       = { for k, v in aws_subnet.public : k => v.id }
}

output "private_subnet_ids" {
  description = "Map of AZ to private subnet IDs"
  value       = { for k, v in aws_subnet.private : k => v.id }
}

# output "nat_instance_ids" {
#   description = "Map of AZ to NAT instance IDs"
#   value       = var.enable_nat_instance ? { for k, v in module.nat_instance : k => v.instance_id } : {}
# }

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "availability_zones" {
  description = "List of availability zones in the region"
  value       = var.availability_zones
}