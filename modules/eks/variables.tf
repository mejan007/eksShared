variable "cluster_name" {
  description = "Name for the EKS cluster."
  type        = string
}

variable "subnet_ids" {
  description = "List of VPC Subnet IDs (typically private) for the worker nodes and EKS ENIs."
  type        = list(string)
}