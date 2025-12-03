
# # 1️⃣ Null resource to delete aws-node and kube-proxy
# resource "null_resource" "delete_aws_cni_and_kube_proxy" {
#   # Ensure nodes exist before deleting
#   depends_on = [aws_eks_node_group.node_group]

#   triggers = {
#     cluster_endpoint = aws_eks_cluster.eks_cluster.endpoint
#   }

#   provisioner "local-exec" {
#     command = <<EOT
#       # Configure kubectl
#       aws eks update-kubeconfig --name ${var.cluster_name} --region ${var.aws_region}

#       # Delete the default AWS CNI DaemonSet
#       kubectl -n kube-system delete daemonset aws-node --ignore-not-found

#       # Delete kube-proxy DaemonSet (will be replaced by Cilium)
#       kubectl -n kube-system delete daemonset kube-proxy --ignore-not-found
#     EOT
#   }
# }


# resource "helm_release" "cilium" {
#   name       = "cilium"
#   repository = "https://helm.cilium.io/"
#   chart      = "cilium"
#   version    = "1.14.0"
#   namespace  = "kube-system"

#   # Ensure deletion happens first
#   depends_on = [null_resource.delete_aws_cni_and_kube_proxy]

#   # Overlay / VXLAN mode configuration
#   set { name = "ipam.mode" value = "kubernetes" }
#   set { name = "tunnel" value = "vxlan" }
#   set { name = "podCIDR" value = "10.0.0.0/16" }

#   # Enable network policies
#   set { name = "policy.enabled" value = "true" }

#   # Replace kube-proxy
#   set { name = "kubeProxyReplacement" value = "true" }

#   # Gateway API support
#   set { name = "gatewayAPI.enabled" value = "true" }

#   # Kubernetes API endpoint
#   set { name = "k8sServiceHost" value = replace(aws_eks_cluster.eks_cluster.endpoint, "https://", "") }
#   set { name = "k8sServicePort" value = "443" }
# }





# resource "helm_release" "metrics_server" {
#   name       = "metrics-server"
#   repository = "https://kubernetes-sigs.github.io/metrics-server/"
#   chart      = "metrics-server"
#   namespace  = "kube-system"
#   version    = "5.12.0"
# }


# resource "aws_eks_addon" "coredns" {
#   cluster_name          = aws_eks_cluster.eks_cluster.name
#   addon_name            = "coredns"
#   resolve_conflicts     = "OVERWRITE"
#   service_account_role_arn = aws_iam_role.eks_addon_sa.arn



# # --------------------------------------------------------------------------------

# Delete AWS CNI and kube-proxy before installing Cilium
# resource "null_resource" "delete_aws_cni_and_kube_proxy" {
#   depends_on = [aws_eks_node_group.node_group]

#   triggers = {
#     cluster_endpoint = module.eks.cluster_endpoint
#   }

#   provisioner "local-exec" {
#     command = <<EOT
#       aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}
#       kubectl -n kube-system delete daemonset aws-node --ignore-not-found
#       kubectl -n kube-system delete daemonset kube-proxy --ignore-not-found
#     EOT
#   }
# }

# Install Cilium using the Cilium Terraform provider
resource "cilium" "overlay" {
  name     = "cilium"
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  namespace  = "kube-system"
  depends_on = [null_resource.delete_aws_cni_and_kube_proxy]

  version = "1.14.5"

  set = [
    "eni.enabled=false",
    "ipam.mode=cluster-pool",                     # Use cluster-pool IPAM mode
    "data_path=tunnel",                      
    "tunnel=vxlan",                              # Overlay mode
    "ipam.operator.clusterPoolIPv4PodCIDRList[0]=172.20.0.0/16", # Must not overlap with VPC
    "ipam.operator.clusterPoolIPv4MaskSize=30",                       
    "policy.enabled=true",                        # Enable network policy
    "gatewayAPI.enabled=true",                    # Enable Gateway API
    "kubeProxyReplacement=true",                 # Replace kube-proxy
    "k8sServiceHost=${replace(aws_eks_cluster.eks_cluster.endpoint, "https://", "")}",
    "k8sServicePort=443",
    # Observability
    "hubble.enabled=true",

    "hubble.relay.enabled=true",

    # Use eBPF for masquerading (NAT) traffic leaving the cluster instead of iptables
    "bpf.masquerade=true"
  ]

  wait = true
}


# -------------------
# CHECK BEFORE APPLY
# -------------------------

# resource "null_resource" "delete_aws_cni" {
#   provisioner "local-exec" {
#     command = "curl -s -k -XDELETE -H 'Authorization: Bearer ${data.aws_eks_cluster_auth.eks_vpc_us_east_1.token}' -H 'Accept: application/json' -H 'Content-Type: application/json' '${data.aws_eks_cluster.eks_vpc_us_east_1.endpoint}/apis/apps/v1/namespaces/kube-system/daemonsets/aws-node'"
#   }
# }

# resource "null_resource" "delete_kube_proxy" {
#   provisioner "local-exec" {
#     command = "curl -s -k -XDELETE -H 'Authorization: Bearer ${data.aws_eks_cluster_auth.eks_vpc_us_east_1.token}' -H 'Accept: application/json' -H 'Content-Type: application/json' '${data.aws_eks_cluster.eks_vpc_us_east_1.endpoint}/apis/apps/v1/namespaces/kube-system/daemonsets/kube-proxy'"
#   }
# }



# resource "null_resource" "delete_aws_cni_and_kube_proxy" {
#   # 1. Run this AFTER the control plane exists, but BEFORE (or during) node creation.
#   #    Do not wait for nodes to be "Ready" (they won't be without a CNI).
#   depends_on = [module.eks]

#   triggers = {
#     endpoint = module.eks.cluster_endpoint
#   }

#   provisioner "local-exec" {
#     # 2. Use environment variables to pass auth securely without writing files
#     environment = {
#       KUBE_ENDPOINT = module.eks.cluster_endpoint
#       # Requires the `aws_eks_cluster_auth` data source
#       KUBE_TOKEN    = data.aws_eks_cluster_auth.eks_cluster_auth.token 
#     }

#     # 3. Use kubectl with explicit server and token. 
#     #    --insecure-skip-tls-verify is used because EKS CA setup in local-exec is complex, 
#     #    but valid here since we trust the endpoint output from Terraform.
#     command = <<EOT
#       kubectl \
#         --server=$KUBE_ENDPOINT \
#         --token=$KUBE_TOKEN \
#         --insecure-skip-tls-verify=true \
#         -n kube-system delete daemonset aws-node kube-proxy --ignore-not-found
#     EOT
#   }
# }


# data "aws_eks_cluster_auth" "eks_cluster_auth" {
#   name = module.eks.cluster_name
# }