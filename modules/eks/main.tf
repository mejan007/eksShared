resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn

  # Specify VPC subnets where EKS will create its ENIs
  vpc_config {
    public_access_cidrs = var.public_access_cidrs

    subnet_ids = var.subnet_ids
    # Set to true to allow public access to the Kube API endpoint
    endpoint_public_access = true 
    # Set to true to allow private access from within the VPC
    endpoint_private_access = true
  }

  dynamic "kubernetes_network_config" {
    for_each = var.enable_kubernetes_network_config ? [1] : []

    content {
      service_ipv4_cidr = var.service_ipv4_cidr

      ip_family = var.ip_family
    
      dynamic "elastic_load_balancing" {
        for_each = var.enable_elastic_load_balancing ? [1] : []
        content {
          enabled = true
        }
      }
    }
  }

  dynamic "encryption_config" {
    for_each = var.enable_encryption_config ? [1] : []

    content {
      provider {
        key_arn = var.encryption_key_arn
      }
      resources = ["secrets"]
    }
  }

  dynamic "access_config" {
    for_each = var.enable_access_config ? [1] : []
    content {
      authentication_mode = var.authentication_mode
      bootstrap_cluster_creator_admin_permissions = var.bootstrap_cluster_creator_admin_permissions
    }
  }

  

  tags = {
    Name = var.cluster_name
  }


  # Ensure the IAM role is created before the cluster
  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}
