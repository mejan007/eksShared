

# Install Cilium using the Cilium Terraform provider
# resource "cilium" "overlay" {
#   name     = "cilium"
#   repository = "https://helm.cilium.io/"
#   chart      = "cilium"
#   namespace  = "kube-system"

#   version = "1.14.5"

#   set = [
#     "eni.enabled=false",
#     "ipam.mode=cluster-pool",                     # Use cluster-pool IPAM mode
#     "data_path=tunnel",                      
#     "tunnel=vxlan",                              # Overlay mode
#     "ipam.operator.clusterPoolIPv4PodCIDRList[0]=172.20.0.0/16", # Must not overlap with VPC
#     "ipam.operator.clusterPoolIPv4MaskSize=24",                       
#     "policy.enabled=true",                        # Enable network policy
#     "gatewayAPI.enabled=true",                    # Enable Gateway API
#     "kubeProxyReplacement=true",                 # Replace kube-proxy
#     "k8sServiceHost=${replace(aws_eks_cluster.eks_cluster.endpoint, "https://", "")}",
#     "k8sServicePort=443",
#     # Observability
#     "hubble.enabled=true",

#     "hubble.relay.enabled=true",

#     # Use eBPF for masquerading (NAT) traffic leaving the cluster instead of iptables
#     "bpf.masquerade=true",
#     "hostNetworking=true",
#   ]

#   wait = true
# }
