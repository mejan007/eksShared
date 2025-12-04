terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    cilium = {
      source  = "littlejo/cilium"
      version = "~> 0.3.2"}
  }
}

provider "aws" {
  region = var.aws_region
}

provider "cilium" {
  config_path = "~/.kube/config"
}
