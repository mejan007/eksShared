variable "cluster_name" {
  description = "Name for the EKS cluster."
  type        = string
}

variable "subnet_ids" {
  description = "List of VPC Subnet IDs (typically private) for the worker nodes and EKS ENIs."
  type        = list(string)
}
variable "aws_region" {
  description = "AWS region for the EKS cluster."
  type        = string
}

variable "instance_types" {
  description = "List of instance types for the EKS worker nodes."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "disk_size" {
  description = "Disk size (in GiB) for the EKS worker nodes."
  type        = number
  default     = 20
}
variable "capacity_type" {
  description = "Capacity type for the EKS worker nodes (e.g., ON_DEMAND, SPOT)."
  type        = string
  default     = "ON_DEMAND"
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that are allowed access to the public Kubernetes API server endpoint."
  type        = list(string)
  default     = []
}

variable "enable_elastic_load_balancing" {
  description = "Boolean to enable or disable elastic load balancing in the EKS cluster."
  type        = bool
  default     = false
}

variable "service_ipv4_cidr" {
  description = "The CIDR block to assign Kubernetes service IPs."
  type        = string
  default     = ""
}

variable "ip_family" {
  description = "The IP family used for pod and service IPs."
  type        = string
  default     = "ipv4"
}

variable "enable_kubernetes_network_config" {
  description = "Boolean to enable or disable kubernetes network config in the EKS cluster."
  type        = bool
  default     = false
}

variable "enable_encryption_config" {
  description = "Boolean to enable or disable encryption config in the EKS cluster."
  type        = bool
  default     = false
}

variable "encryption_key_arn" {
  type    = string
  default = ""
}

variable "enable_access_config" {
  type    = bool
  default = true
}

variable "authentication_mode" {
  type    = string
  default = ""
}

variable "bootstrap_cluster_creator_admin_permissions" {
  type    = bool
  default = true
}

variable "project_name" {
  type    = string
  default = "eks-training"

}

variable "ec2_role_for_eks" {
  type        = string
  description = "ec2 role for the eks access identity"

}



variable "ec2_roles_for_eks" {
  type        = list(string)
  description = "List of IAM role ARNs to be granted access to the EKS cluster."

  default = [
    "arn:aws:iam::702865854817:role/self-hosted-runner-role"
  ]
}


variable "launch_template_ebs_size" {
  description = "Size of the EBS volume for the launch template."
  type        = number
  default     = 30

}
variable "launch_template_ebs_encryption_flag" {
  description = "Whether the EBS volume for the launch template is encrypted."
  type        = bool
  default     = true
}
variable "capacity_reservation_preference" {
  description = "The capacity reservation preference for the launch template."
  type        = string
  default     = "open"

}
variable "cpu_core_count" {
  description = "The number of CPU cores for the launch template."
  type        = number
  default     = 2
}
variable "cpu_threads_per_core" {
  description = "The number of threads per CPU core for the launch template."
  type        = number
  default     = 1
}
variable "credit_specification_cpu_credits" {
  description = "The CPU credit option for the launch template."
  type        = string
  default     = "standard"
}
variable "disable_api_stop" {
  description = "Whether to disable API stop for the launch template."
  type        = bool
  default     = true
}
variable "disable_api_termination" {
  description = "Whether to disable API termination for the launch template."
  type        = bool
  default     = true
}
variable "ebs_optimized" {
  description = "Whether the launch template is EBS optimized."
  type        = bool
  default     = true
}
variable "ami_id" {
  description = "AMI ID for the launch template."
  type        = string
  default     = "ami-0fa3fe0fa7920f68e"
}

variable "instance_initiated_shutdown_behavior" {
  description = "The shutdown behavior for instances launched from the launch template."
  type        = string
  default     = "terminate"
}
variable "instance_market_type" {
  description = "The market type for instances launched from the launch template."
  type        = string
  default     = "spot"
}
variable "instance_type" {
  description = "The instance type for instances launched from the launch template."
  type        = string
  default     = "t3.medium"
}
variable "key_name" {
  description = "The key name for instances launched from the launch template."
  type        = string
  default     = "eks-key"
}
variable "metadata_options_http_endpoint" {
  description = "The http endpoint setting for instances launched from the launch template."
  type        = string
  default     = "enabled"
}
variable "metadata_options_http_tokens" {
  description = "The http tokens setting for instances launched from the launch template."
  type        = string
  default     = "required"
}
variable "metadata_options_http_put_response_hop_limit" {
  description = "The http put response hop limit for instances launched from the launch template."
  type        = number
  default     = 1
}
variable "metadata_options_instance_metadata_tags" {
  description = "The instance metadata tags setting for instances launched from the launch template."
  type        = string
  default     = "enabled"
}
variable "monitoring_enabled" {
  description = "Whether monitoring is enabled for instances launched from the launch template."
  type        = bool
  default     = true
}
variable "network_interface_associate_public_ip_address" {
  description = "Whether to associate a public IP address with the network interface for instances launched from the launch template."
  type        = bool
  default     = false
}
variable "placement_availability_zone" {
  description = "The availability zone for instances launched from the launch template."
  type        = string
  default     = "us-east-1a"
}
variable "launch_template_security_group_ids" {
  description = "List of security group IDs for the launch template."
  type        = list(string)
  default     = []

}

variable "karpenter_namespace" {
  description = "Namespace where Karpenter will be deployed"
  type        = string
  default     = "kube-system"
}
