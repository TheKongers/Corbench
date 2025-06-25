#!/bin/bash
# Setup EBS CSI driver after cluster creation

set -e

# Disable AWS CLI pager to prevent interactive prompts
export AWS_PAGER=""

echo "Setting up EBS CSI driver..."

# Get AWS account ID from worker role ARN or current identity
AWS_ACCOUNT_ID=$(echo ${EKS_WORKER_ROLE_ARN} | cut -d':' -f5 2>/dev/null || aws sts get-caller-identity --query Account --output text)

# Get current OIDC provider URL from the cluster
OIDC_PROVIDER=$(aws eks describe-cluster --name ${CLUSTER_NAME} --region ${ZONE} --query "cluster.identity.oidc.issuer" --output text | sed 's|https://||')
OIDC_ID=$(echo ${OIDC_PROVIDER} | cut -d'/' -f4)

echo "Creating IAM role for EBS CSI driver..."

echo "Printing OIDC provider: ${OIDC_ID}"

# Connect kubectl to the cluster
aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${ZONE}

# Create OIDC provider if it doesn't exist
echo "Creating OIDC provider..."
aws iam create-open-id-connect-provider \
  --url https://${OIDC_PROVIDER} \
  --thumbprint-list 9e99a48a9960b14926bb7f3b02e22da2b0ab7280 \
  --client-id-list sts.amazonaws.com || echo "OIDC provider already exists, continuing..."

# Create trust policy
cat > ebs-csi-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${OIDC_PROVIDER}:aud": "sts.amazonaws.com",
          "${OIDC_PROVIDER}:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }
  ]
}
EOF

# Create IAM role (ignore error if already exists)
aws iam create-role \
  --role-name AmazonEKS_EBS_CSI_DriverRole \
  --assume-role-policy-document file://ebs-csi-trust-policy.json \
  --region ${ZONE} || echo "Role already exists, continuing..."

# Update trust policy for existing role to ensure correct OIDC provider
aws iam update-assume-role-policy \
  --role-name AmazonEKS_EBS_CSI_DriverRole \
  --policy-document file://ebs-csi-trust-policy.json

# Attach AWS managed policy
aws iam attach-role-policy \
  --role-name AmazonEKS_EBS_CSI_DriverRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --region ${ZONE}

echo "Installing EBS CSI driver addon..."

# Install EBS CSI driver addon
aws eks create-addon \
  --cluster-name ${CLUSTER_NAME} \
  --addon-name aws-ebs-csi-driver \
  --service-account-role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/AmazonEKS_EBS_CSI_DriverRole \
  --region ${ZONE} || echo "Addon already exists, updating..."

# Wait for addon to be active
echo "Waiting for EBS CSI driver to be active..."
aws eks wait addon-active \
  --cluster-name ${CLUSTER_NAME} \
  --addon-name aws-ebs-csi-driver \
  --region ${ZONE}

# Annotate service account with IAM role
echo "Annotating EBS CSI service account..."
kubectl annotate serviceaccount ebs-csi-controller-sa \
  -n kube-system \
  eks.amazonaws.com/role-arn=arn:aws:iam::${AWS_ACCOUNT_ID}:role/AmazonEKS_EBS_CSI_DriverRole \
  --overwrite

# Apply storage class
kubectl apply -f gp2-csi-storageclass.yaml

# Clean up temp files
rm -f ebs-csi-trust-policy.json

echo "EBS CSI driver setup complete!"