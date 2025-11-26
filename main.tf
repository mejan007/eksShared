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

# module "eks" {
#   source       = "./modules/eks"
#   cluster_name = "ase-eks-cluster"
#   subnet_ids   = values(module.vpc.private_subnet_ids)
#   aws_region   = var.aws_region
# }

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
  security_group_id = aws_security_group.eks_to_rds_prod[0].id
  db_name           = var.rds_database_name
  db_instance_class = var.rds_instance_class
  allocated_storage = var.rds_allocated_storage
  engine_version    = var.rds_engine_version

  depends_on = [ module.eks ]
}

# Security Group: Allow EKS to connect to RDS
resource "aws_security_group" "eks_to_rds_prod" {
  count       = var.create_rds
  name        = "eks-to-rds-prod-${count.index}"
  description = "Allow EKS cluster to connect to RDS MySQL"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description                = "Allow inbound MySQL from the EKS service"
    from_port                  = 3306
    to_port                    = 3306
    protocol                   = "tcp"
    security_groups            = [module.eks.cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-to-rds-prod-${count.index}"
  }

  depends_on = [module.eks]
}

module "eks" {
  source       = "./modules/eks"
  cluster_name = "ase-eks-cluster"
  subnet_ids   = values(module.vpc.private_subnet_ids)
  aws_region   = var.aws_region
}

module "ec2" {
  source                      = "./modules/ec2"
  root_volume_size            = 25
  ami_id                      = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = values(module.vpc.public_subnet_ids)[0]
  key_name                    = var.key_name
  vpc_id                      = module.vpc.vpc_id
  associate_public_ip_address = true
  sg_ingress_rules = [
    {
      description = "Allow HTTPS"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Allow HTTP"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Allow SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

}

resource "aws_security_group_rule" "bastion_to_eks_controlplane" {
  description              = "Allow bastion to access EKS API endpoint"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"

  security_group_id        = module.eks.cluster_security_group_id
  source_security_group_id = module.ec2.created_security_group_id
}
