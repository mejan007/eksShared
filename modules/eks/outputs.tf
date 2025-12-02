output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.eks_cluster.name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.eks_cluster.arn
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS cluster API server"
  value       = aws_eks_cluster.eks_cluster.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID of the EKS cluster control plane"
  value       = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.eks_cluster.certificate_authority[0].data
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS"
  value       = aws_iam_openid_connect_provider.eks_oidc.arn
}

# output "node_group_name" {
#   description = "Name of the EKS node group"
#   value       = aws_eks_node_group.node_group.node_group_name
# }

# output "node_group_arn" {
#   description = "ARN of the EKS node group"
#   value       = aws_eks_node_group.node_group.arn
# }

# output "node_group_status" {
#   description = "Status of the EKS node group"
#   value       = aws_eks_node_group.node_group.status
# }

# output "node_group_role_arn" {
#   description = "IAM role ARN associated with the node group"
#   value       = aws_eks_node_group.node_group.node_role_arn
# }
output "ebs_encryption_key_arn" {
  description = "ARN of the KMS key used for EBS encryption"
  value       = aws_kms_key.eks_launch_template_cmk.arn
  
}