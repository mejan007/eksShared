## call modules


# RDS module for production
module "rds_postgres" {
  count             = var.create_rds
  source            = "./modules/rds"
  create_rds        = 1
  project_name      = var.project_name
  environment       = "prod"
  vpc_id            = module.vpc["prod"].vpc_id
  subnet_ids        = values(module.vpc["prod"].private_subnet_ids_by_az)
  security_group_id = aws_security_group.rds_sg_prod[0].id
  db_name           = var.rds_database_name
  db_instance_class = var.rds_instance_class
  allocated_storage = var.rds_allocated_storage
  engine_version    = var.rds_engine_version
}

# Security Group Rule: Allow EKS to connect to RDS.
# TODO: need to give actual source security group:
resource "aws_security_group_rule" "eks_to_rds_prod" {
  count                    = var.create_rds
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg_prod[0].id
  source_security_group_id = module.eks_prod[0].eks_service_sg_id
  description              = "Allow inbound PostgreSQL from the EKS service"
}
