

# Install Cilium using the Cilium Terraform provider
# resource "cilium" "overlay" {
# #   name     = "cilium"
#   repository = "https://helm.cilium.io/"
# #   chart      = "cilium"
# #   namespace  = "kube-system"

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
#     # "kubeProxyReplacement=false",                 # Replace kube-proxy
#     # "k8sServiceHost=${replace(module.eks.cluster_endpoint, "https://", "")}",
#     # "k8sServicePort=443",
#     # Observability
#     "hubble.enabled=true",
    

#     "hubble.relay.enabled=true",
#     "hubble.ui.enabled=true",

#     # Use eBPF for masquerading (NAT) traffic leaving the cluster instead of iptables
#     # "bpf.masquerade=true",
#     # "hostNetworking=true",
#   ]

#   wait = true
# }

resource "helm_release" "helmCilium" {
  name       = "cilium"
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  namespace  = "kube-system"

  version = "1.14.5"

  set {
    name  = "eni.enabled"
    value = "false"
  }

  set {
    name  = "ipam.mode"
    value = "cluster-pool"
  }

  set {
    name  = "data_path"
    value = "tunnel"
  }

  set {
    name  = "tunnel"
    value = "vxlan"
  }

  set {
    name  = "ipam.operator.clusterPoolIPv4PodCIDRList[0]"
    value = "172.20.0.0/16"
  }

  set {
    name  = "ipam.operator.clusterPoolIPv4MaskSize"
    value = "24"
  }

  set {
    name  = "policy.enabled"
    value = "true"
  }

  set {
    name  = "gatewayAPI.enabled"
    value = "false"
  }

  # kube-proxy replacement (commented out like original)
  # set {
  #   name  = "kubeProxyReplacement"
  #   value = "false"
  # }

  # set {
  #   name  = "k8sServiceHost"
  #   value = replace(module.eks.cluster_endpoint, "https://", "")
  # }

  # set {
  #   name  = "k8sServicePort"
  #   value = "443"
  # }

  # Hubble / observability
  set {
    name  = "hubble.enabled"
    value = "true"
  }

  set {
    name  = "hubble.relay.enabled"
    value = "true"
  }

  set {
    name  = "hubble.ui.enabled"
    value = "true"
  }

  # masquerading, hostNetworking (kept commented exactly)
  # set {
  #   name  = "bpf.masquerade"
  #   value = "true"
  # }

  # set {
  #   name  = "hostNetworking"
  #   value = "true"
  # }

  wait = true
}

