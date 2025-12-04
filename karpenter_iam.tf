# #
# # Karpenter IAM Roles and Policies
# # Reference: https://karpenter.sh/docs/getting-started/migrating-from-cas/
# #
# # This file creates the IAM roles required for Karpenter:
# # 1. KarpenterNodeRole - IAM role for nodes provisioned by Karpenter
# # 2. KarpenterControllerRole - IAM role for the Karpenter controller (IRSA)
# #

# # =============================================================================
# # DATA SOURCES
# # =============================================================================

# data "aws_partition" "current" {}

# data "aws_caller_identity" "karpenter" {}

# data "aws_region" "current" {}

# # Get EKS cluster info (assumes module.eks exists)
# data "aws_eks_cluster" "karpenter" {
#   name = var.cluster_name
# }

# # =============================================================================
# # VARIABLES
# # =============================================================================

# variable "cluster_name" {
#   description = "Name of the EKS cluster"
#   type        = string
# }

# variable "karpenter_namespace" {
#   description = "Namespace where Karpenter will be deployed"
#   type        = string
#   default     = "kube-system"
# }

# variable "enable_karpenter" {
#   description = "Enable Karpenter resources"
#   type        = bool
#   default     = false
# }

# variable "oidc_provider_arn" {
#   description = "ARN of the OIDC provider for the EKS cluster"
#   type        = string
# }

# variable "oidc_provider_url" {
#   description = "URL of the OIDC provider (without https://)"
#   type        = string
# }

# # =============================================================================
# # KARPENTER NODE IAM ROLE
# # =============================================================================
# # This role is assumed by EC2 instances provisioned by Karpenter

# resource "aws_iam_role" "karpenter_node" {
#   count = var.enable_karpenter ? 1 : 0

#   name        = "KarpenterNodeRole-${var.cluster_name}"
#   description = "IAM role for nodes provisioned by Karpenter"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })

#   tags = {
#     Name      = "KarpenterNodeRole-${var.cluster_name}"
#     Cluster   = var.cluster_name
#     Component = "karpenter"
#   }
# }

# # Attach required AWS managed policies to node role
# resource "aws_iam_role_policy_attachment" "karpenter_node_eks_worker" {
#   count = var.enable_karpenter ? 1 : 0

#   policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
#   role       = aws_iam_role.karpenter_node[0].name
# }

# resource "aws_iam_role_policy_attachment" "karpenter_node_eks_cni" {
#   count = var.enable_karpenter ? 1 : 0

#   policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
#   role       = aws_iam_role.karpenter_node[0].name
# }

# resource "aws_iam_role_policy_attachment" "karpenter_node_ecr" {
#   count = var.enable_karpenter ? 1 : 0

#   policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
#   role       = aws_iam_role.karpenter_node[0].name
# }

# resource "aws_iam_role_policy_attachment" "karpenter_node_ssm" {
#   count = var.enable_karpenter ? 1 : 0

#   policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
#   role       = aws_iam_role.karpenter_node[0].name
# }

# # Instance profile for Karpenter nodes
# resource "aws_iam_instance_profile" "karpenter_node" {
#   count = var.enable_karpenter ? 1 : 0

#   name = "KarpenterNodeInstanceProfile-${var.cluster_name}"
#   role = aws_iam_role.karpenter_node[0].name

#   tags = {
#     Name      = "KarpenterNodeInstanceProfile-${var.cluster_name}"
#     Cluster   = var.cluster_name
#     Component = "karpenter"
#   }
# }

# # =============================================================================
# # KARPENTER CONTROLLER IAM ROLE (IRSA)
# # =============================================================================
# # This role is assumed by the Karpenter controller pod via IRSA

# resource "aws_iam_role" "karpenter_controller" {
#   count = var.enable_karpenter ? 1 : 0

#   name        = "KarpenterControllerRole-${var.cluster_name}"
#   description = "IAM role for Karpenter controller"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Federated = var.oidc_provider_arn
#         }
#         Action = "sts:AssumeRoleWithWebIdentity"
#         Condition = {
#           StringEquals = {
#             "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
#             "${var.oidc_provider_url}:sub" = "system:serviceaccount:${var.karpenter_namespace}:karpenter"
#           }
#         }
#       }
#     ]
#   })

#   tags = {
#     Name      = "KarpenterControllerRole-${var.cluster_name}"
#     Cluster   = var.cluster_name
#     Component = "karpenter"
#   }
# }

# # Karpenter Controller Policy
# resource "aws_iam_role_policy" "karpenter_controller" {
#   count = var.enable_karpenter ? 1 : 0

#   name = "KarpenterControllerPolicy-${var.cluster_name}"
#   role = aws_iam_role.karpenter_controller[0].id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "Karpenter"
#         Effect = "Allow"
#         Action = [
#           "ssm:GetParameter",
#           "ec2:DescribeImages",
#           "ec2:RunInstances",
#           "ec2:DescribeSubnets",
#           "ec2:DescribeSecurityGroups",
#           "ec2:DescribeLaunchTemplates",
#           "ec2:DescribeInstances",
#           "ec2:DescribeInstanceTypes",
#           "ec2:DescribeInstanceTypeOfferings",
#           "ec2:DeleteLaunchTemplate",
#           "ec2:CreateTags",
#           "ec2:CreateLaunchTemplate",
#           "ec2:CreateFleet",
#           "ec2:DescribeSpotPriceHistory",
#           "pricing:GetProducts"
#         ]
#         Resource = "*"
#       },
#       {
#         Sid    = "ConditionalEC2Termination"
#         Effect = "Allow"
#         Action = "ec2:TerminateInstances"
#         Resource = "*"
#         Condition = {
#           StringLike = {
#             "ec2:ResourceTag/karpenter.sh/nodepool" = "*"
#           }
#         }
#       },
#       {
#         Sid      = "PassNodeIAMRole"
#         Effect   = "Allow"
#         Action   = "iam:PassRole"
#         Resource = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.karpenter.account_id}:role/KarpenterNodeRole-${var.cluster_name}"
#       },
#       {
#         Sid      = "EKSClusterEndpointLookup"
#         Effect   = "Allow"
#         Action   = "eks:DescribeCluster"
#         Resource = "arn:${data.aws_partition.current.partition}:eks:${data.aws_region.current.name}:${data.aws_caller_identity.karpenter.account_id}:cluster/${var.cluster_name}"
#       },
#       {
#         Sid      = "AllowScopedInstanceProfileCreationActions"
#         Effect   = "Allow"
#         Action   = ["iam:CreateInstanceProfile"]
#         Resource = "*"
#         Condition = {
#           StringEquals = {
#             "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
#             "aws:RequestTag/topology.kubernetes.io/region"             = data.aws_region.current.name
#           }
#           StringLike = {
#             "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass" = "*"
#           }
#         }
#       },
#       {
#         Sid    = "AllowScopedInstanceProfileTagActions"
#         Effect = "Allow"
#         Action = ["iam:TagInstanceProfile"]
#         Resource = "*"
#         Condition = {
#           StringEquals = {
#             "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
#             "aws:ResourceTag/topology.kubernetes.io/region"             = data.aws_region.current.name
#             "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}"  = "owned"
#             "aws:RequestTag/topology.kubernetes.io/region"              = data.aws_region.current.name
#           }
#           StringLike = {
#             "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" = "*"
#             "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass"  = "*"
#           }
#         }
#       },
#       {
#         Sid    = "AllowScopedInstanceProfileActions"
#         Effect = "Allow"
#         Action = [
#           "iam:AddRoleToInstanceProfile",
#           "iam:RemoveRoleFromInstanceProfile",
#           "iam:DeleteInstanceProfile"
#         ]
#         Resource = "*"
#         Condition = {
#           StringEquals = {
#             "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
#             "aws:ResourceTag/topology.kubernetes.io/region"             = data.aws_region.current.name
#           }
#           StringLike = {
#             "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" = "*"
#           }
#         }
#       },
#       {
#         Sid      = "AllowInstanceProfileReadActions"
#         Effect   = "Allow"
#         Action   = "iam:GetInstanceProfile"
#         Resource = "*"
#       },
#       {
#         Sid      = "AllowUnscopedInstanceProfileListAction"
#         Effect   = "Allow"
#         Action   = "iam:ListInstanceProfiles"
#         Resource = "*"
#       }
#     ]
#   })
# }

# # =============================================================================
# # OUTPUTS
# # =============================================================================

# output "karpenter_node_role_arn" {
#   description = "ARN of the Karpenter node IAM role"
#   value       = var.enable_karpenter ? aws_iam_role.karpenter_node[0].arn : null
# }

# output "karpenter_node_role_name" {
#   description = "Name of the Karpenter node IAM role"
#   value       = var.enable_karpenter ? aws_iam_role.karpenter_node[0].name : null
# }

# output "karpenter_controller_role_arn" {
#   description = "ARN of the Karpenter controller IAM role"
#   value       = var.enable_karpenter ? aws_iam_role.karpenter_controller[0].arn : null
# }

# output "karpenter_controller_role_name" {
#   description = "Name of the Karpenter controller IAM role"
#   value       = var.enable_karpenter ? aws_iam_role.karpenter_controller[0].name : null
# }

# output "karpenter_instance_profile_name" {
#   description = "Name of the Karpenter node instance profile"
#   value       = var.enable_karpenter ? aws_iam_instance_profile.karpenter_node[0].name : null
# }

# output "karpenter_instance_profile_arn" {
#   description = "ARN of the Karpenter node instance profile"
#   value       = var.enable_karpenter ? aws_iam_instance_profile.karpenter_node[0].arn : null
# }
