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


resource "aws_iam_role" "irsa_role" {
  name = "${var.project_name}-example-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks_oidc.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:default:eks-serviceaccount"
        }
      }
    }]
  })
}

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
