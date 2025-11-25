resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.common_tags, { Name = var.vpc_name })
}

resource "aws_subnet" "public" {
  for_each                = { for idx, cidr in var.public_subnet_cidrs : var.availability_zones[idx] => cidr }
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true
  tags                    = merge(var.common_tags, { Name = "${var.name_prefix}public-${each.key}" })
}

resource "aws_subnet" "private" {
  for_each          = { for idx, cidr in var.private_subnet_cidrs : var.availability_zones[idx] => cidr }
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = each.key
  tags              = merge(var.common_tags, { Name = "${var.name_prefix}private-${each.key}" })
}

resource "aws_internet_gateway" "igw" {
  count  = length(var.public_subnet_cidrs) > 0 ? 1 : 0
  vpc_id = aws_vpc.main.id
  tags   = merge(var.common_tags, { Name = "${var.name_prefix}igw" })
}

resource "aws_route_table" "public" {
  for_each = aws_subnet.public
  vpc_id   = aws_vpc.main.id
  tags     = merge(var.common_tags, { Name = "${var.name_prefix}public-rt-${each.key}" })
}

resource "aws_route" "public_internet" {
  for_each               = aws_subnet.public
  route_table_id         = aws_route_table.public[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw[0].id
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public[each.key].id
}

resource "aws_route_table" "private" {
  for_each = aws_subnet.private
  vpc_id   = aws_vpc.main.id
  tags     = merge(var.common_tags, { Name = "${var.name_prefix}private-rt-${each.key}" })
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_eip" "nat" {
  for_each = var.enable_nat_gateway ? aws_subnet.public : {}
  domain   = "vpc"
  tags     = merge(var.common_tags, { Name = "${var.name_prefix}nat-eip-${each.key}" })
}

resource "aws_nat_gateway" "nat" {
  for_each      = var.enable_nat_gateway ? aws_subnet.public : {}
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id
  tags          = merge(var.common_tags, { Name = "${var.name_prefix}nat-gw-${each.key}" })
  depends_on    = [aws_internet_gateway.igw]
}

resource "aws_route" "private_nat_gw" {
  for_each               = var.enable_nat_gateway ? aws_route_table.private : {}
  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[each.key].id
}

# resource "aws_route" "private_nat_instance" {
#   for_each               = var.enable_nat_instance && var.nat_instance_ami != "" ? aws_route_table.private : {}
#   route_table_id         = each.value.id
#   destination_cidr_block = "0.0.0.0/0"
#   network_interface_id   = module.nat_instance[each.key].network_interface_id
# }

# module "nat_instance" {
#   for_each = var.enable_nat_instance && var.nat_instance_ami != "" ? aws_subnet.public : {}
#   source   = "../ec2"

#   ami                 = var.nat_instance_ami
#   instance_type       = "t2.micro"
#   vpc_id              = aws_vpc.main.id
#   subnet_id           = each.value.id
#   private_cidrs       = [for s in values(aws_subnet.private) : s.cidr_block if s.availability_zone == each.key]
#   is_test_instance    = false
#   is_public           = true
#   source_dest_check   = false
#   associate_public_ip = true
#   create_eip          = true
#   # user_data          = <<-EOF
#   #   #!/bin/bash
#   #   sysctl -w net.ipv4.ip_forward=1
#   #   echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
#   #   EOF
#   tags        = merge(var.common_tags, { Name = "${var.name_prefix}nat-instance-${each.key}" })
#   common_tags = var.common_tags
#   name_prefix = var.name_prefix
#   depends_on  = [aws_internet_gateway.igw]
# }