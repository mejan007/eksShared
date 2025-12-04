data "aws_caller_identity" "current" {}


resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn

  # Specify VPC subnets where EKS will create its ENIs
  vpc_config {
    # public_access_cidrs = var.public_access_cidrs

    subnet_ids = var.subnet_ids
    # Set to true to allow public access to the Kube API endpoint
    endpoint_public_access = false
    # Set to true to allow private access from within the VPC
    endpoint_private_access = true
  }
  bootstrap_self_managed_addons = false

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
      authentication_mode                         = var.authentication_mode
      bootstrap_cluster_creator_admin_permissions = var.bootstrap_cluster_creator_admin_permissions
    }
  }



  tags = {
    Name = var.cluster_name
  }


  # Ensure the IAM role is created before the cluster
  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# resource "aws_eks_addon" "vpc_cni" {
#   cluster_name  = aws_eks_cluster.eks_cluster.name
#   addon_version = "v1.20.4-eksbuild.1"
#   addon_name    = "vpc-cni"
# }

# resource "aws_eks_addon" "kube_proxy" {
#   cluster_name  = aws_eks_cluster.eks_cluster.name
#   addon_version = "v1.34.1-eksbuild.2"
#   addon_name    = "kube-proxy"
# }

resource "aws_eks_addon" "core_dns" {
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_version               = "v1.12.4-eksbuild.1"  
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  
  depends_on = [aws_eks_node_group.node_group]
}

resource "aws_eks_addon" "metrics_server" {
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_version               = "v0.8.0-eksbuild.5"
  addon_name                  = "metrics-server"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  
  depends_on = [aws_eks_node_group.node_group]
}

resource "aws_kms_key" "eks_launch_template_cmk" {
  description             = "KMS key for EKS Launch Template EBS volume encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 20
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-1"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        },
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow administration of the key"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        },
        Action = [
          "kms:ReplicateKey",
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ],
        Resource = "*"
      },
      {
        Sid    = "Allow use of the key"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        },
        Action = [
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext"
        ],
        Resource = "*"
      },
      {
        Sid    = "Allow EBS to use the key"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }

    ]
  })
}

resource "aws_autoscaling_lifecycle_hook" "launch" {
  name                   = "lifecycle-hook-launch-for-${var.cluster_name}"
  autoscaling_group_name = aws_eks_node_group.node_group.resources[0].autoscaling_groups[0].name
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_LAUNCHING"
  heartbeat_timeout      = 300
  default_result         = "CONTINUE"
}

resource "aws_autoscaling_lifecycle_hook" "terminate" {
  name                   = "lifecycle-hook-terminate-for-${var.cluster_name}"
  autoscaling_group_name = aws_eks_node_group.node_group.resources[0].autoscaling_groups[0].name
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
  heartbeat_timeout      = 300
  default_result         = "CONTINUE"
}


resource "aws_launch_template" "eks_launch_template" {
  name = "${var.cluster_name}-launch-template"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = var.launch_template_ebs_size
      encrypted   = var.launch_template_ebs_encryption_flag
      kms_key_id  = var.launch_template_ebs_encryption_flag ? aws_kms_key.eks_launch_template_cmk.arn : null
      volume_type = "gp3"
    }
  }

  capacity_reservation_specification {
    capacity_reservation_preference = var.capacity_reservation_preference
  }

  # cpu_options {
  #   core_count       = var.cpu_core_count
  #   threads_per_core = var.cpu_threads_per_core
  # }

  credit_specification {
    cpu_credits = var.credit_specification_cpu_credits
  }

  # disable_api_stop        = var.disable_api_stop
  # disable_api_termination = var.disable_api_termination

  ebs_optimized = var.ebs_optimized

  # image_id removed - letting AWS manage AMI via ami_type in node group

  # instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior

  instance_type = var.instance_type

  key_name = var.key_name

  # user_data removed - AWS handles bootstrap automatically when ami_type is set


  metadata_options {
    http_endpoint               = var.metadata_options_http_endpoint
    http_tokens                 = var.metadata_options_http_tokens
    http_put_response_hop_limit = var.metadata_options_http_put_response_hop_limit
    instance_metadata_tags      = var.metadata_options_instance_metadata_tags
  }

  monitoring {
    enabled = var.monitoring_enabled
  }

  network_interfaces {
    associate_public_ip_address = var.network_interface_associate_public_ip_address
    security_groups             = var.launch_template_security_group_ids
  }

  # placement {
  #   availability_zone = var.placement_availability_zone
  # }


  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.cluster_name}-launch-template"
    }
  }
  depends_on = [var.launch_template_security_group_ids]
}


resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.cluster_name}-node-group-new"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.subnet_ids
  ami_type        = "AL2023_x86_64_STANDARD"

  capacity_type = var.capacity_type
  launch_template {
    id      = aws_launch_template.eks_launch_template.id
    version = "$Latest"
  }
  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  tags = {
    Name = "${var.cluster_name}-node-groups"
  }
  
  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
  
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.node_group-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_group-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_group-AmazonEC2ContainerRegistryReadOnly,
    # aws_eks_addon.vpc_cni,
    # aws_eks_addon.kube_proxy,
  ]
}

data "aws_eks_cluster" "eks" {
  name = aws_eks_cluster.eks_cluster.name
}

data "tls_certificate" "oidc" {
  url = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks_oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
  url             = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer

  depends_on = [aws_eks_cluster.eks_cluster]
}

