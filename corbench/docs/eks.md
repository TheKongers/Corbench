# EKS Deployment

[Elastic Kubernetes Service (EKS)](https://aws.amazon.com/eks/).

## Setup Corbench

### 1. Create the Main Node
---

1. **Create Security Credentials**:
    - Create [security credentials](https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html) on AWS.
    - Store the credentials in a YAML file as follows:

    ```yaml
    accesskeyid: <Amazon access key>
    secretaccesskey: <Amazon access secret>
    ```

2. **Create a VPC**:
    - Set up a [VPC](https://docs.aws.amazon.com/eks/latest/userguide/create-public-private-vpc.html) with public subnets. (you may already have premade vpcss in your region, you can use those as well)

3. **Create IAM Roles**:
    - **EKS Cluster Role**: Create an [Amazon EKS cluster role](https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html) with the following policy:
        - `AmazonEKSclusterPolicy`
        - `AmazonEBSCSIDriverPolicy`
    - **EKS Worker Node Role**: Create an [Amazon EKS worker node role](https://docs.aws.amazon.com/eks/latest/userguide/worker_node_IAM_role.html) with the following policies:
        - `AmazonEKSWorkerNodePolicy`
        - `AmazonEKS_CNI_Policy`
        - `AmazonEC2ContainerRegistryReadOnly`
        - `AmazonEBSCSIDriverPolicy`
        - `AmazonSSMManagedInstanceCore`
        - A custom inline policy with the following JSON:
    ```json
    {
	"Version": "2012-10-17",
	"Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "ec2:CreateVolume",
                    "ec2:DeleteVolume",
                    "ec2:AttachVolume",
                    "ec2:DetachVolume",
                    "ec2:DescribeVolumes",
                    "ec2:DescribeInstances",
                    "ec2:DescribeSnapshots",
                    "ec2:CreateSnapshot",
                    "ec2:DeleteSnapshot",
                    "ec2:DescribeTags",
                    "ec2:CreateTags",
                    "ec2:DeleteTags"
                ],
                "Resource": "*"
            }
        ]
    }
    ```

4. **Set Environment Variables and Deploy the Cluster**:

    IMPORTANT: Before running any make commands locally, make sure to build the infra tool in the /infra directory for your computer! The current build may not be sutible for your machine's archetecture, but make sure if you are uploading the corbench docker image to always build for linux/amd64. More details can be found in [corbench/infra/README.md](../infra/README.md)

    ```bash
    export AUTH_FILE=<path to yaml credentials file that was created in the last step>
    export CLUSTER_NAME=corbench
    export ZONE=<the zone you are choosing to host on determined by account, vpc, etc>
    export EKS_WORKER_ROLE_ARN=<Amazon EKS worker node IAM role ARN>
    export EKS_CLUSTER_ROLE_ARN=<Amazon EKS cluster role ARN>
    export SEPARATOR=, 
    export EKS_SUBNET_IDS=SUBNETID1,SUBNETID2,SUBNETID3
    make cluster_create
    ```
    - make sure to run the make command in the /corbench directory

### 2. Deploy Monitoring Components

---

> **Note**: These components are responsible for collecting, monitoring, and displaying test results and logs.

1. **Optional GitHub Integration**:
    - If used with GitHub integration, generate a GitHub auth token:
        - Login with the [Corbench account](https://github.com/corbench) and generate a [new auth token](https://github.com/settings/tokens).
        - Add required permissions: `public_repo`, `read:org`, `write:discussion`.

    ```bash
    export GRAFANA_ADMIN_PASSWORD=password
    export DOMAIN_NAME=prombench.prometheus.io # Can be set to any other custom domain or an empty string if not used with the GitHub integration.
    export OAUTH_TOKEN=<generated token from GitHub or set to an empty string " ">
    export WH_SECRET=<GitHub webhook secret>
    export GITHUB_ORG=cortexproject
    export GITHUB_REPO=cortex
    export SERVICEACCOUNT_CLIENT_EMAIL=<Your AWS Account ARN>
    ```

2. **Deploy the Monitoring Components**:
    - This step will deploy the [nginx-ingress-controller](https://github.com/kubernetes/ingress-nginx), Prometheus-Meta, and Grafana

    ```bash
    make cluster_resource_apply
    ```

3. **Configure DNS**:
    - The output will display the ingress IP. Use this IP to point the domain name.
    - Set the `A record` for `<DOMAIN_NAME>` to point to the `nginx-ingress-controller` IP address.

4. **Access the Services**:
    - Grafana: `http://<DOMAIN_NAME>/grafana`
    - Prometheus: `http://<DOMAIN_NAME>/prometheus-meta`

## Usage

### 1. Start a Benchmarking Test Manually

---

1. **Set the Environment Variables**:

    ```bash
    export RELEASE=<cortex-tag of cortex release for PR to be benchmarked against. List of tags can be found at https://hub.docker.com/r/cortexproject/cortex/tags>
    export PR_NUMBER=<PR to benchmark against the selected $RELEASE>
    ```

2. **Create Nodegroups for Kubernetes Objects**:

    ```bash
    make node_create
    ```

3. **Deploy the Kubernetes Objects**:

    ```bash
    make resource_apply
    ```

### 2. Stopping a Benchmarking Test Manually

---

1. **Set the Environment Variables**:

    ```bash
    export AUTH_FILE=<path to yaml credentials file that was created>
    export CLUSTER_NAME=corbench
    export SEPARATOR=,
    export EKS_WORKER_ROLE_ARN=<Amazon EKS worker node IAM role ARN>
    export EKS_CLUSTER_ROLE_ARN=<Amazon EKS cluster role ARN>
    export EKS_SUBNET_IDS=SUBNETID1,SUBNETID2,SUBNETID3
    export ZONE=<the zone you are choosing to host on determined by account, vpc, etc>
    export PROVIDER=eks

    export PR_NUMBER=<PR to benchmark against the selected $RELEASE>
    ```

2. **Delete Nodegroups (Keeping the Main Node Intact)**:

    ```bash
    make clean
    ```

3. **Delete Everything (Complete Teardown)**:

    ```bash
    make cluster_delete
    ```
