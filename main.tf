## call modules
module "vpc" {
  source               = "./modules/vpc"
  vpc_name             = "${var.project_name}-vpc"
  public_subnet_cidrs  = ["10.0.0.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.3.0/24"]
  availability_zones   = ["us-east-1a", "us-east-1b"]
  enable_igw           = true
  enable_nat_gateway   = true
}

module "eks" {
  source       = "./modules/eks"
  cluster_name = "ase-eks-cluster"
  subnet_ids   = values(module.vpc.private_subnet_ids)
  aws_region   = var.aws_region
}

# RDS module for production
module "rds_mysql" {
  count             = var.create_rds
  source            = "./modules/rds"
  create_rds        = 1
  project_name      = var.project_name
  engine            = "mysql"
  environment       = "prod"
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = values(module.vpc.private_subnet_ids)
  security_group_id = aws_security_group.rds_sg_prod[0].id
  db_name           = var.rds_database_name
  db_instance_class = var.rds_instance_class
  allocated_storage = var.rds_allocated_storage
  engine_version    = var.rds_engine_version
}

# Security Group Rule: Allow EKS to connect to RDS.
resource "aws_security_group_rule" "eks_to_rds_prod" {
  count                    = var.create_rds
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg_prod[0].id
  source_security_group_id = module.eks.cluster_security_group_id
  description              = "Allow inbound MySQL from the EKS service"
}


