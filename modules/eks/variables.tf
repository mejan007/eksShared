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
  type = string 
  description = "ec2 role for the eks access identity"
  
}