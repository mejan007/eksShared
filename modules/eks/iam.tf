resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}


resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}


resource "aws_iam_role" "node_group" {
  name = "${var.cluster_name}-eks-node-group-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "node_group-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ssm" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node_group.name
}


resource "aws_iam_instance_profile" "node_group" {
  name = "${var.cluster_name}-eks-node-group-instance-profile"
  role = aws_iam_role.node_group.name

}
resource "aws_iam_role_policy" "kms_for_worker" {
  name = "${var.cluster_name}-eks-worker-kms-policy"
  role = aws_iam_role.node_group.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:CreateGrant"
        ]
        Resource = aws_kms_key.eks_launch_template_cmk.arn
      }
    ]
  })

}


# resource "aws_iam_role" "irsa_role" {
#   name = "${var.project_name}-example-irsa-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Principal = {
#         Federated = aws_iam_openid_connect_provider.eks_oidc.arn
#       }
#       Action = "sts:AssumeRoleWithWebIdentity"
#       Condition = {
#         StringEquals = {
#           "${replace(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:default:eks-serviceaccount"
#         }
#       }
#     }]
#   })
# }

# IAM Roles and Policies for AWS Load Balancer Controller

resource "aws_iam_policy" "alb_controller_policy" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "IAM policy for ALB controller"
  policy      = file("${path.module}/iam_policy.json")
}

resource "aws_iam_role" "alb_controller_role" {
  name = "${var.cluster_name}-eks-alb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks_oidc.arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "${replace(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "alb_controller_attach" {
  role       = aws_iam_role.alb_controller_role.name
  policy_arn = aws_iam_policy.alb_controller_policy.arn
}


### EKS Acess Entries ( Instead of aws-auth ConfigMap)

resource "aws_eks_access_entry" "eks_access_entry" {
  for_each      = toset(var.ec2_roles_for_eks)
  cluster_name  = aws_eks_cluster.eks_cluster.name
  principal_arn = each.value

  type = "STANDARD"
}


resource "aws_eks_access_policy_association" "eks_access_policy_association" {

  for_each = toset(var.ec2_roles_for_eks)

  cluster_name  = aws_eks_cluster.eks_cluster.name
  principal_arn = each.value



  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  # principal_arn = aws_eks_access_entry.eks_access_entry.principal_arn

  access_scope {
    type = "cluster"

  }
}

# =============================================================================
# KARPENTER NODE ACCESS ENTRY
# =============================================================================
# This allows Karpenter-provisioned nodes to join the cluster
# Using the existing node_group role since it already has the required policies

resource "aws_eks_access_entry" "karpenter_nodes" {
  cluster_name  = aws_eks_cluster.eks_cluster.name
  principal_arn = aws_iam_role.node_group.arn
  type          = "EC2_LINUX"  # Required for EC2 nodes to join the cluster

  tags = {
    Name      = "KarpenterNodeAccessEntry-${var.cluster_name}"
    Component = "karpenter"
  }
}

#=============================================================================
# KARPENTER CONTROLLER IAM ROLE (IRSA)
# =============================================================================

resource "aws_iam_role" "karpenter_controller" {
  name        = "KarpenterControllerRole-${var.cluster_name}"
  description = "IAM role for Karpenter controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks_oidc.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:aud" = "sts.amazonaws.com"
            "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub" = "system:serviceaccount:${var.karpenter_namespace}:karpenter"
          }
        }
      }
    ]
  })

  tags = {
    Name      = "KarpenterControllerRole-${var.cluster_name}"
    Cluster   = var.cluster_name
    Component = "karpenter"
  }
}

# Karpenter Controller Policy
resource "aws_iam_role_policy" "karpenter_controller" {

  name = "KarpenterControllerPolicy-${var.cluster_name}"
  role = aws_iam_role.karpenter_controller.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Karpenter"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ec2:DescribeImages",
          "ec2:RunInstances",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DeleteLaunchTemplate",
          "ec2:CreateTags",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:DescribeSpotPriceHistory",
          "pricing:GetProducts"
        ]
        Resource = "*"
      },
      {
        Sid    = "ConditionalEC2Termination"
        Effect = "Allow"
        Action = "ec2:TerminateInstances"
        Resource = "*"
        Condition = {
          StringLike = {
            "ec2:ResourceTag/karpenter.sh/nodepool" = "*"
          }
        }
      },
      {
        Sid      = "PassNodeIAMRole"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = aws_iam_role.node_group.arn
      },
      {
        Sid      = "EKSClusterEndpointLookup"
        Effect   = "Allow"
        Action   = "eks:DescribeCluster"
        Resource = "arn:${data.aws_partition.current.partition}:eks:${data.aws_region.current.name}:${data.aws_caller_identity.karpenter.account_id}:cluster/${var.cluster_name}"
      },
      {
        Sid      = "AllowScopedInstanceProfileCreationActions"
        Effect   = "Allow"
        Action   = ["iam:CreateInstanceProfile"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
            "aws:RequestTag/topology.kubernetes.io/region"             = data.aws_region.current.name
          }
          StringLike = {
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass" = "*"
          }
        }
      },
      {
        Sid    = "AllowScopedInstanceProfileTagActions"
        Effect = "Allow"
        Action = ["iam:TagInstanceProfile"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
            "aws:ResourceTag/topology.kubernetes.io/region"             = data.aws_region.current.name
            "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}"  = "owned"
            "aws:RequestTag/topology.kubernetes.io/region"              = data.aws_region.current.name
          }
          StringLike = {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" = "*"
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass"  = "*"
          }
        }
      },
      {
        Sid    = "AllowScopedInstanceProfileActions"
        Effect = "Allow"
        Action = [
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:DeleteInstanceProfile"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
            "aws:ResourceTag/topology.kubernetes.io/region"             = data.aws_region.current.name
          }
          StringLike = {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" = "*"
          }
        }
      },
      {
        Sid      = "AllowInstanceProfileReadActions"
        Effect   = "Allow"
        Action   = "iam:GetInstanceProfile"
        Resource = "*"
      },
      {
        Sid      = "AllowUnscopedInstanceProfileListAction"
        Effect   = "Allow"
        Action   = "iam:ListInstanceProfiles"
        Resource = "*"
      }
    ]
  })
}