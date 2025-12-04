
# Security Group: Allow EKS to connect to RDS
resource "aws_security_group" "eks_to_rds_prod" {
  count       = var.create_rds
  name        = "eks-to-rds-prod-${count.index}"
  description = "Allow EKS cluster to connect to RDS MySQL"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow inbound MySQL from the EKS service"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
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

resource "aws_security_group_rule" "bastion_to_eks_controlplane" {
  description = "Allow bastion to access EKS API endpoint"
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"

  security_group_id = module.eks.cluster_security_group_id
  cidr_blocks       = ["10.0.0.0/16"]
}


resource "aws_security_group" "eks_worker_node_sg" {
  name        = "eks-worker-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = module.vpc.vpc_id

  # ingress {
  #   description = "Allow bastion to access worker nodes"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["10.0.0.0/16"]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


}
resource "aws_security_group_rule" "node_to_node" {
  description              = "Allow worker nodes to communicate with each other"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_worker_node_sg.id
  source_security_group_id = aws_security_group.eks_worker_node_sg.id
  depends_on               = [aws_security_group.eks_worker_node_sg]
}

# Allow worker nodes to communicate with the control plane
resource "aws_security_group_rule" "worker_to_controlplane" {
  description              = "Allow worker nodes to communicate with control plane"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = module.eks.cluster_security_group_id
  source_security_group_id = aws_security_group.eks_worker_node_sg.id
  depends_on               = [aws_security_group.eks_worker_node_sg, module.eks]
}

# Allow control plane to communicate with worker nodes (kubelet)
resource "aws_security_group_rule" "controlplane_to_worker" {
  description              = "Allow control plane to communicate with worker nodes"
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_worker_node_sg.id
  source_security_group_id = module.eks.cluster_security_group_id
  depends_on               = [aws_security_group.eks_worker_node_sg, module.eks]
}

# Allow control plane to reach worker nodes for extensions (metrics, logs, etc)
resource "aws_security_group_rule" "controlplane_to_worker_extensions" {
  description              = "Allow control plane to worker nodes for extension API calls"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_worker_node_sg.id
  source_security_group_id = module.eks.cluster_security_group_id
  depends_on               = [aws_security_group.eks_worker_node_sg, module.eks]
}