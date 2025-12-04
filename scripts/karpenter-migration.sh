#!/bin/bash
#
# Karpenter Migration Script
# Migrates from Cluster Autoscaler to Karpenter
# Reference: https://karpenter.sh/docs/getting-started/migrating-from-cas/
#
# Prerequisites:
# - AWS CLI configured
# - kubectl configured
# - Helm 3 installed
# - Existing EKS cluster with OIDC provider
#

set -e

# =============================================================================
# CONFIGURATION - Update these variables for your environment
# =============================================================================

CLUSTER_NAME="${CLUSTER_NAME:-ase-eks-cluster}"
KARPENTER_NAMESPACE="${KARPENTER_NAMESPACE:-kube-system}"
KARPENTER_VERSION="${KARPENTER_VERSION:-1.8}"
AWS_PARTITION="${AWS_PARTITION:-aws}"

# Auto-detect from AWS CLI
AWS_REGION="${AWS_REGION:-$(aws configure list | grep region | tr -s " " | cut -d" " -f3)}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-$(aws sts get-caller-identity --query 'Account' --output text)}"
OIDC_ENDPOINT="${OIDC_ENDPOINT:-$(aws eks describe-cluster --name "${CLUSTER_NAME}" --query "cluster.identity.oidc.issuer" --output text)}"
K8S_VERSION="${K8S_VERSION:-$(aws eks describe-cluster --name "${CLUSTER_NAME}" --query "cluster.version" --output text)}"

echo "=========================================="
echo "Karpenter Migration Configuration"
echo "=========================================="
echo "CLUSTER_NAME: ${CLUSTER_NAME}"
echo "KARPENTER_VERSION: ${KARPENTER_VERSION}"
echo "AWS_REGION: ${AWS_REGION}"
echo "AWS_ACCOUNT_ID: ${AWS_ACCOUNT_ID}"
echo "OIDC_ENDPOINT: ${OIDC_ENDPOINT}"
echo "K8S_VERSION: ${K8S_VERSION}"
echo "=========================================="

# # =============================================================================
# # STEP 1: Create Karpenter Node IAM Role
# # =============================================================================

# # In eks/iam.tf

# # =============================================================================
# # STEP 2: Create Karpenter Controller IAM Role (IRSA)
# # =============================================================================


# # In eks/iam.tf



# =============================================================================
# STEP 3: Tag Subnets and Security Groups for Karpenter Discovery
# =============================================================================
tag_resources() {
    echo ""
    echo ">>> Step 3: Tagging subnets and security groups for Karpenter discovery..."

    # Tag subnets from all node groups
    for NODEGROUP in $(aws eks list-nodegroups --cluster-name "${CLUSTER_NAME}" --query 'nodegroups' --output text); do
        echo "Tagging subnets for nodegroup: ${NODEGROUP}"
        SUBNETS=$(aws eks describe-nodegroup --cluster-name "${CLUSTER_NAME}" \
            --nodegroup-name "${NODEGROUP}" --query 'nodegroup.subnets' --output text)
        
        aws ec2 create-tags \
            --tags "Key=karpenter.sh/discovery,Value=${CLUSTER_NAME}" \
            --resources ${SUBNETS} 2>/dev/null || true
    done

    # Tag security groups
    NODEGROUP=$(aws eks list-nodegroups --cluster-name "${CLUSTER_NAME}" \
        --query 'nodegroups[0]' --output text)

    # Get launch template info
    LAUNCH_TEMPLATE=$(aws eks describe-nodegroup --cluster-name "${CLUSTER_NAME}" \
        --nodegroup-name "${NODEGROUP}" --query 'nodegroup.launchTemplate.{id:id,version:version}' \
        --output text | tr -s " \t" ",")

    if [ -n "${LAUNCH_TEMPLATE}" ] && [ "${LAUNCH_TEMPLATE}" != "None" ]; then
        # Get security groups from launch template
        SECURITY_GROUPS=$(aws ec2 describe-launch-template-versions \
            --launch-template-id "${LAUNCH_TEMPLATE%,*}" --versions "${LAUNCH_TEMPLATE#*,}" \
            --query 'LaunchTemplateVersions[0].LaunchTemplateData.[NetworkInterfaces[0].Groups||SecurityGroupIds]' \
            --output text 2>/dev/null) || true
    fi

    echo "Tagging security groups: ${SECURITY_GROUPS}"
    aws ec2 create-tags \
        --tags "Key=karpenter.sh/discovery,Value=${CLUSTER_NAME}" \
        --resources ${SECURITY_GROUPS} 2>/dev/null || true

    echo "✓ Resources tagged for Karpenter discovery"
}

# # =============================================================================
# # STEP 4: Update aws-auth ConfigMap
# # =============================================================================
# update_aws_auth() {
#     echo ""
#     echo ">>> Step 4: Updating aws-auth ConfigMap..."
#     echo ""
#     echo "Add the following entry to the mapRoles section of aws-auth ConfigMap:"
#     echo ""
#     echo "kubectl edit configmap aws-auth -n kube-system"
#     echo ""
#     cat << EOF
# # Add this to mapRoles:
# - groups:
#   - system:bootstrappers
#   - system:nodes
#   rolearn: arn:${AWS_PARTITION}:iam::${AWS_ACCOUNT_ID}:role/KarpenterNodeRole-${CLUSTER_NAME}
#   username: system:node:{{EC2PrivateDNSName}}
# EOF
#     echo ""
#     echo "⚠️  Please update aws-auth ConfigMap manually before proceeding!"
# }

# # =============================================================================
# # STEP 5: Deploy Karpenter via Helm
# # =============================================================================
# deploy_karpenter() {
#     echo ""
#     echo ">>> Step 5: Deploying Karpenter..."

#     # Get AMI alias version
#     ALIAS_VERSION=$(aws ssm get-parameter \
#         --name "/aws/service/eks/optimized-ami/${K8S_VERSION}/amazon-linux-2023/x86_64/standard/recommended/image_id" \
#         --query Parameter.Value --output text | xargs aws ec2 describe-images --query 'Images[0].Name' --image-ids 2>/dev/null | sed -r 's/^.*(v[[:digit:]]+).*$/\1/') || ALIAS_VERSION="latest"

#     # Create namespace if not exists
#     kubectl create namespace "${KARPENTER_NAMESPACE}" 2>/dev/null || true

#     # Install Karpenter CRDs
#     echo "Installing Karpenter CRDs..."
#     kubectl create -f "https://raw.githubusercontent.com/aws/karpenter-provider-aws/v${KARPENTER_VERSION}/pkg/apis/crds/karpenter.sh_nodepools.yaml" 2>/dev/null || true
#     kubectl create -f "https://raw.githubusercontent.com/aws/karpenter-provider-aws/v${KARPENTER_VERSION}/pkg/apis/crds/karpenter.k8s.aws_ec2nodeclasses.yaml" 2>/dev/null || true
#     kubectl create -f "https://raw.githubusercontent.com/aws/karpenter-provider-aws/v${KARPENTER_VERSION}/pkg/apis/crds/karpenter.sh_nodeclaims.yaml" 2>/dev/null || true

#     # Get first nodegroup name for affinity
#     NODEGROUP=$(aws eks list-nodegroups --cluster-name "${CLUSTER_NAME}" \
#         --query 'nodegroups[0]' --output text)

#     # Install Karpenter via Helm
#     echo "Installing Karpenter via Helm..."
#     helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter \
#         --version "${KARPENTER_VERSION}" \
#         --namespace "${KARPENTER_NAMESPACE}" \
#         --set "settings.clusterName=${CLUSTER_NAME}" \
#         --set "settings.interruptionQueue=${CLUSTER_NAME}" \
#         --set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=arn:${AWS_PARTITION}:iam::${AWS_ACCOUNT_ID}:role/KarpenterControllerRole-${CLUSTER_NAME}" \
#         --set controller.resources.requests.cpu=1 \
#         --set controller.resources.requests.memory=1Gi \
#         --set controller.resources.limits.cpu=1 \
#         --set controller.resources.limits.memory=1Gi \
#         --set "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key=karpenter.sh/nodepool" \
#         --set "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator=DoesNotExist" \
#         --set "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].key=eks.amazonaws.com/nodegroup" \
#         --set "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].operator=In" \
#         --set "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].values[0]=${NODEGROUP}" \
#         --wait

#     echo "✓ Karpenter deployed"
# }

# # =============================================================================
# # STEP 6: Create Default NodePool and EC2NodeClass
# # =============================================================================
# create_nodepool() {
#     echo ""
#     echo ">>> Step 6: Creating default NodePool and EC2NodeClass..."

#     # Get AMI alias version
#     ALIAS_VERSION=$(aws ssm get-parameter \
#         --name "/aws/service/eks/optimized-ami/${K8S_VERSION}/amazon-linux-2023/x86_64/standard/recommended/image_id" \
#         --query Parameter.Value --output text | xargs aws ec2 describe-images --query 'Images[0].Name' --image-ids 2>/dev/null | sed -r 's/^.*(v[[:digit:]]+).*$/\1/') || ALIAS_VERSION="latest"

#     cat << EOF | kubectl apply -f -
# apiVersion: karpenter.sh/v1
# kind: NodePool
# metadata:
#   name: default
# spec:
#   template:
#     spec:
#       requirements:
#         - key: kubernetes.io/arch
#           operator: In
#           values: ["amd64"]
#         - key: kubernetes.io/os
#           operator: In
#           values: ["linux"]
#         - key: karpenter.sh/capacity-type
#           operator: In
#           values: ["on-demand"]  # Change to "spot" for spot instances
#         - key: karpenter.k8s.aws/instance-category
#           operator: In
#           values: ["c", "m", "r", "t"]
#         - key: karpenter.k8s.aws/instance-generation
#           operator: Gt
#           values: ["2"]
#       nodeClassRef:
#         group: karpenter.k8s.aws
#         kind: EC2NodeClass
#         name: default
#       expireAfter: 720h  # 30 days
#   limits:
#     cpu: 1000
#   disruption:
#     consolidationPolicy: WhenEmptyOrUnderutilized
#     consolidateAfter: 1m
# ---
# apiVersion: karpenter.k8s.aws/v1
# kind: EC2NodeClass
# metadata:
#   name: default
# spec:
#   role: "KarpenterNodeRole-${CLUSTER_NAME}"
#   amiSelectorTerms:
#     - alias: "al2023@latest"
#   subnetSelectorTerms:
#     - tags:
#         karpenter.sh/discovery: "${CLUSTER_NAME}"
#   securityGroupSelectorTerms:
#     - tags:
#         karpenter.sh/discovery: "${CLUSTER_NAME}"
#   blockDeviceMappings:
#     - deviceName: /dev/xvda
#       ebs:
#         volumeSize: 100Gi
#         volumeType: gp3
#         encrypted: true
# EOF

#     echo "✓ Default NodePool and EC2NodeClass created"
# }

# # =============================================================================
# # STEP 7: Scale Down Cluster Autoscaler
# # =============================================================================
# disable_cas() {
#     echo ""
#     echo ">>> Step 7: Disabling Cluster Autoscaler..."
    
#     kubectl scale deploy/cluster-autoscaler -n kube-system --replicas=0 2>/dev/null || \
#         echo "Cluster Autoscaler not found or already scaled down"

#     echo "✓ Cluster Autoscaler disabled"
# }

# # =============================================================================
# # STEP 8: Verify Karpenter
# # =============================================================================
# verify_karpenter() {
#     echo ""
#     echo ">>> Step 8: Verifying Karpenter deployment..."
    
#     echo ""
#     echo "Karpenter pods:"
#     kubectl get pods -n "${KARPENTER_NAMESPACE}" -l app.kubernetes.io/name=karpenter

#     echo ""
#     echo "NodePools:"
#     kubectl get nodepools

#     echo ""
#     echo "EC2NodeClasses:"
#     kubectl get ec2nodeclasses

#     echo ""
#     echo "To view Karpenter logs:"
#     echo "kubectl logs -f -n ${KARPENTER_NAMESPACE} -l app.kubernetes.io/name=karpenter -c controller"
# }

# # =============================================================================
# # CLEANUP FUNCTION
# # =============================================================================
# cleanup() {
#     echo ""
#     echo ">>> Cleaning up temporary files..."
#     rm -f /tmp/node-trust-policy.json
#     rm -f /tmp/controller-trust-policy.json
#     rm -f /tmp/controller-policy.json
# }

# # =============================================================================
# # MAIN
# # =============================================================================
# main() {
#     echo ""
#     echo "=========================================="
#     echo "   Karpenter Migration Script"
#     echo "=========================================="
#     echo ""
    
#     case "${1:-}" in
#         "iam")
#             create_node_role
#             create_controller_role
#             ;;
#         "tags")
#             tag_resources
#             ;;
#         "aws-auth")
#             update_aws_auth
#             ;;
#         "deploy")
#             deploy_karpenter
#             ;;
#         "nodepool")
#             create_nodepool
#             ;;
#         "disable-cas")
#             disable_cas
#             ;;
#         "verify")
#             verify_karpenter
#             ;;
#         "all")
#             create_node_role
#             create_controller_role
#             tag_resources
#             update_aws_auth
#             echo ""
#             read -p "Press Enter after updating aws-auth ConfigMap..."
#             deploy_karpenter
#             create_nodepool
#             verify_karpenter
#             ;;
#         *)
#             echo "Usage: $0 {iam|tags|aws-auth|deploy|nodepool|disable-cas|verify|all}"
#             echo ""
#             echo "Commands:"
#             echo "  iam         - Create IAM roles for Karpenter"
#             echo "  tags        - Tag subnets and security groups"
#             echo "  aws-auth    - Show aws-auth ConfigMap update instructions"
#             echo "  deploy      - Deploy Karpenter via Helm"
#             echo "  nodepool    - Create default NodePool and EC2NodeClass"
#             echo "  disable-cas - Scale down Cluster Autoscaler"
#             echo "  verify      - Verify Karpenter deployment"
#             echo "  all         - Run all steps in sequence"
#             exit 1
#             ;;
#     esac

#     cleanup
#     echo ""
#     echo "Done!"
# }

# main "$@"
