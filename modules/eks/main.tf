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

  kubernetes_network_config {

    elastic_load_balancing {
      enabled = var.
    }
  }

  tags = {
    Name = var.cluster_name
  }


  # Ensure the IAM role is created before the cluster
  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}
