# Getting Started

[Elastic Kubernetes Service (EKS)](https://aws.amazon.com/eks/).

## Deploying Corbench (For Contributors)

You should already have an aws account set up. All these steps will be using your aws account.
Before starting, it would be helpful to have some sort of note taking system to keep track of everything as there is a LOT of things to remember!

1. **Create IAM User Security Credentials**:
    - These are the steps for creating [security credentials](https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html) on AWS.
    1. Make an IAM User
        -   Go to the IAM Dashboard
        -   Under **IAM Resources** click the number under **Users**. This should take you to the IAM Users page
        -   Click Create User and give it any name you want. Click next
        -   Under Permissions options click the **Attach Policies Directly** option
        -   Add the following policies:
            - `AmazonEC2FullAccess`
            - `AmazonEBSCSIDriverPolicy`
            - `IAMFullAccess`
            - `AmazonEKS_CNI_Policy`
            - `AmazonEKSWorkerNodePolicy`
            - `IAMFullAccess`
        -   Click next
        -   Click Create user
        -   Go to the user that you created in the IAM Users page then under permissions policies, click  **Add permissions** and click **Create inline policy**
        -   In Policy Editor, select **JSON** then paste in the following:
        ```json
        {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Action": [
                        "eks:*",
                        "ec2:DescribeSubnets",
                        "ec2:DescribeVpcs",
                        "ec2:DescribeSecurityGroups",
                        "ec2:CreateSecurityGroup",
                        "ec2:AuthorizeSecurityGroupIngress",
                        "ec2:RevokeSecurityGroupIngress",
                        "ec2:AuthorizeSecurityGroupEgress",
                        "ec2:RevokeSecurityGroupEgress",
                        "ec2:CreateTags",
                        "ec2:DeleteTags",
                        "iam:GetRole",
                        "iam:ListRoles",
                        "iam:PassRole",
                        "iam:ListInstanceProfiles",
                        "cloudformation:*"
                    ],
                    "Resource": "*"
                }
            ]
        }
        ```
        -   click next, then name the policy anything you want. Finally, click create policy
    2. Create the credentials
        -   Go back to the IAM Users page and click on the User you just created
        -   Take note of the user ARN as this will be used in a later step
        -   In the **Summary** tab on the right, click **Create access key**. this should be under Access Key 1
        -   Click under use case choose **Other** then click next
        -   Add a description tag describing the purpose of this access key and where it will be used (Cortex Benchmarking Tool Deployment) then click **Create Access Key**
        -   Note Down the **Access Key** and **Secret Access Key** values. They will be used in an auth YAML file

    - Copy [auth_file.yaml.template](/auth_file.yaml.template) and rename it to auth_file.yaml in the root directory and fill in your actual AWS credentials using the keys you just created. The format should look something like this:

    ```yaml
    accesskeyid: <Access Key>
    secretaccesskey: <Secret Access Key>
    ```

2. **Create Public Subnets**:
    - Set up a [VPC](https://docs.aws.amazon.com/eks/latest/userguide/create-public-private-vpc.html) with public subnets. Steps are below (you may already have premade vpcs in your region, you can use those as well):
    1. Go to the VPC Dashboard in your aws account
    2. Click **Create VPC** and make sure that **VPC and more** is selected
    3. Under **Number of Availability Zones** choose 3
    4. Under **Number of private subnets** choose 0
    5. Leave everything else the same and click **Create VPC**
    6. After successful creation, click **View VPC** or go to your VPC you just created
    7. Under **Resource Map** you should see 3 subnets. For every subnet, hover over the subnet and a link icon should appear on the right of the subnet icon. Click it to go to the subnet details
    8. Under Details, you should see the **Subnet ID**. Note down all 3 subnet ids as you will need them later.
    9. For every subnet, click the **actions** button on the right, and select **Edit subnet settings** from the dropdown, then under **Auto-assign IP settings**, check the box that says **Enable auto-assign public IPv4 address**. Make sure to do this for every subnet

3. **Create IAM Roles**:
    - **EKS Cluster Role**: Create an [Amazon EKS cluster role](https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html) with the following policy:
        - `AmazonEKSclusterPolicy`
        - `AmazonEBSCSIDriverPolicy`
    1. Go to the IAM Dashboard
    2. Under **IAM Resources** click the number under **Roles**. This should take you to the IAM Roles page
    3. Click **Create Role**
    4. Keep Trusted entity type as AWS Service, and under the Service or use case dropdown select **EKS**.
    5. More options should pop up. Select EKS - Cluster
    6. Click Next
    7. Click Next again
    8. Name the role anything you want (perhaps CorbenchClusterRole), and click **Create role**
    9. Go back to the IAM Roles page, and click on the role you just created
    10. Under Summary, there should be the role ARN. Keep this value noted as you will need it later.
    11. Under Permissions policies click Add Permissions, then Attach Policies
    12. Select `AmazonEBSCSIDriverPolicy` and click **Add Permissions**

    - **EKS Worker Node Role**: Create an Amazon EKS worker node role with the following policies:
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
    1. Go to the IAM Dashboard
    2. Under **IAM Resources** click the number under **Roles**. This should take you to the IAM Roles page
    3. Click **Create Role**
    4. Keep Trusted entity type as AWS Service, and under the Service or use case dropdown select **EC2**.
    6. Click Next
    7. Select the following policies:
        - `AmazonEKSWorkerNodePolicy`
        - `AmazonEKS_CNI_Policy`
        - `AmazonEBSCSIDriverPolicy`
        - `AmazonSSMManagedInstanceCore`
        - `AmazonEC2FullAccess`
        - `AmazonEC2ContainerRegistryReadOnly`
    8. click
    9. Name the role anything you want (perhaps CorbenchWorkerNodeRole), and click **Create role**
    10. Go back to the IAM Roles page, and click on the role you just created
    11. Under Summary, there should be the role ARN. Keep this value noted as you will need it later.

4. **Set Environment Variables and Deploy the Cluster**:

    Before running any make commands locally, make sure to build the infra tool in the /infra directory for your computer. 
    From the root directory:
    ```bash
    cd corbench
    cd infra
    go build -o infra infra.go
    ```
    
    More details for building infra for docker upload (non-local) can be found in [corbench/infra/README.md](../infra/README.md)


    Finally you can put all the setup and noted values to use! Inject these env variables into your terminal
    From the root directory:
    ```bash
    cd corbench
    export AUTH_FILE=../auth_file.yaml
    export CLUSTER_NAME=corbench
    export ZONE=<the zone you are choosing to host on determined by account, vpc, etc. ex: us-west-2>
    export EKS_CLUSTER_ROLE_ARN=<Cluster IAM role ARN>
    export EKS_WORKER_ROLE_ARN=<Worker Node IAM role ARN>
    export SEPARATOR=, 
    export EKS_SUBNET_IDS=<SUBNETID1>,<SUBNETID2>,<SUBNETID3>
    ```

    ```bash
    make cluster_create
    ```

    After this, your cluster should start to deploy! This should take around 10 minutes. You can check the status in your eks account, as well as the CLI that will spit out status updates.

    If something fails, or you forgot to do something, you can run the following command to delete the cluster (this command takes aroudnd 10 minutes):

    ```bash
    make cluster_delete
    ```

    then you can retry by running `make cluster_create` again.


### 2. Deploy Main Node Pods & Integrate with GitHub Repo

---

> **Note**: These components are responsible for collecting, monitoring, and displaying test results and logs, as well as monitoring for github comments

1. **GitHub Integration 1/2**:
    - First generate a GitHub auth token:
        - Login with the [Corbench github account](https://github.com/corbench) (the credentials to this github account can be found in my handoff doc for my internship) and generate a [new auth token](https://github.com/settings/tokens).
        Steps:
        1. After logging into the account, go to settings, then click on **Developer Settigns**. This should be near the bottom of the left hand side options.
        2. Click on **Personal access tokens** then choose **Tokens (classic)**
        3. Click **Generate new token** then from the dropdown options select **Generate new token (classic)**
        4. Under **Node** add a general description of what the access token is for (Cortex Benchmark Integration)
        5. Select your token expiry period to **No expiration** or choose a time frame but keep in mind you have to keep updating and redeploying the tool every time the token expires if you decide to choose an expiry date.
        6. Select the following scopes: `public_repo`, `read:org`, `write:discussion`
        7. scroll to the bottom and click **Generate token**
        8. Take note of the token as you will need it for github integration
        9. Give the Corbench github account repository contributor permissions to allow it to send messages. (this can be done in the respository settings)

2. **Main Node Pods Deployment**:
    Now we are ready to deploy the comment monitor, Prometheus, and grafana pods in the main node.
    Export the following env variables:
    ```bash
    export GRAFANA_ADMIN_PASSWORD=password
    export DOMAIN_NAME=corbench.cortexproject.io
    export OAUTH_TOKEN=<generated github token created in previous step>
    export WH_SECRET=<GitHub webhook secret. You can set this to anything you want, but make sure to note down what you set it to as this will be used to authenticate the payload for Github Webhooks>
    export GITHUB_ORG=cortexproject
    export GITHUB_REPO=cortex
    export SERVICEACCOUNT_CLIENT_EMAIL=<AWS IAM User Account ARN. This is the ARN of the IAM User you made earlier on in the deployment. This is not an email.>
    ```
    Assuming you have the ENV variabls exported from the **Set Environment Variables and Deploy the Cluster** step as well,

    From root directory:
    ```bash
    cd corbench
    make cluster_resource_apply
    ```
    This command should take less than 5 minutes. If you would like to try again if something went wrong, you can run `make cluster_delete` and redeploy the cluster with `make cluster_create` then run `make cluster_resource_apply` again

    In the output, an ingress IP will be displayed. Note this down as this will be the entrypoint for the resources on this cluster. It should look something like this for example: http://a8adb2fbc32dc4bad8857e009581d6d2-1038785616.us-west-2.elb.amazonaws.com:80.

    You can access the services at:
    - Grafana: `http://<ingress IP>/grafana`
    - Prometheus: `http://<ingress IP>/prometheus-meta`

    Note that in the [comment monitor config](../c-manifests/cluster-infra/5a_commentmonitor_configmap_noparse.yaml), the links to these services are hard coded. you must manually input the links from the new ingress IP that you just aquired, and run 
    ```bash
    kubectl apply -f <path to 7a_commentmonitor_configmap_noparse.yaml>
    kubectl rollout restart deployment/comment-monitor
    ```
    to update the comment monitor deployment. In the future, you can replace `<ingress IP>` with `{{ index . "DOMAIN_NAME" }}` in the [comment monitor config](../c-manifests/cluster-infra/5a_commentmonitor_configmap_noparse.yaml) when we purchase a domain name we can use. After getting a domain name we would need to set the `A record` for `<DOMAIN_NAME>` to point to the `nginx-ingress-controller` IP address that we just noted down.

    Optional: At this point, you can try to run a benchmark test locally as a test to see if it works. Refer to the **## Starting a Benchmark test locally** section near the bottom of this doc

3. **GitHub Integration 2/2**
    We are now ready to setup full integration with the Cortex repo.

    1. Go to the Cortex repo settings
    2. On the left navigation column, click on **Webhooks**
    3. Click **Add Webhook**
    4. In Payload URL enter `<ingress IP>/hook` using the ingress IP you noted in the previous step(for example, `http://a8adb2fbc32dc4bad8857e009581d6d2-1038785616.us-west-2.elb.amazonaws.com:80/hook`)
    5. Change **Content Type** to `application/json`
    6. Under **Secret**, enter in the webhook secret you created and passed as an ENV variable in step 2. **Main Node Pods Deployment**.
    7. Under **Which events would you like to trigger this webhook?** click **Let me select individual events.**
    8. Uncheck every box except for the **Issue comments** box.
    9. Click **Add webhook**

    The webhook should be set up! To give it a test, create a PR and type in /corbench and a response should show up. Next we will set up the github workflow to enable benchmark testing.

    Next, we need to add repository secrets. Steps are below:
    1. Go to Cortex repo settings
    2. On the left nav bar, click on **Secrets and Variales** then from the options that drop down, click on **actions**
    3. Click **New Repository Secret**
    4. Name the secret `EKS_CLUSTER_ROLE_ARN` and put in your `<Cluster IAM role ARN>` as the value. then click **add secret**
    5. Repeat the steps above for `EKS_WORKER_ROLE_ARN` putting in the value `<Worker Node IAM role ARN>` and also for `EKS_SUBNET_IDS` putting in the value `<SUBNETID1>,<SUBNETID2>,<SUBNETID3>` (these are the same as the enviroment variables you exported in previous steps)
    6. Again make a secret named `TEST_INFRA_PROVIDER_AUTH` but with the base64 encoded value of your `auth_file.yaml` file. Instructions on how to do this are below.

    The secret `TEST_INFRA_PROVIDER_AUTH` is special, it needs to be base64 encoded. You should have filled out your auth_file.yaml with your credentials, so from the root directory, run:

    ```bash
    base64 -i auth_file.yaml
    ```

    Copy the output, then make a repository secret with the name `TEST_INFRA_PROVIDER_AUTH` and the value you just copied from the output.


    In the cortex repo, in the `.github/workflows/` directory, add the following yml file and name it corbench.yml (or whatever you want):
    ```yaml
    on:
    repository_dispatch:
        types: [corbench_start, corbench_stop]
    name: Corbench Workflow
    permissions:
    contents: read
    env:
    AUTH_FILE: ${{ secrets.TEST_INFRA_PROVIDER_AUTH }}
    CLUSTER_NAME: corbench
    DOMAIN_NAME: corbench.cortex.io
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    GITHUB_ORG: cortexproject
    GITHUB_REPO: cortex
    GITHUB_STATUS_TARGET_URL: https://github.com/${{github.repository}}/actions/runs/${{github.run_id}}
    LAST_COMMIT_SHA: ${{ github.event.client_payload.LAST_COMMIT_SHA }}
    PR_NUMBER: ${{ github.event.client_payload.PR_NUMBER }}
    RELEASE: ${{ github.event.client_payload.CORTEX_TAG }}
    ZONE: us-west-2
    EKS_WORKER_ROLE_ARN: ${{ secrets.EKS_WORKER_ROLE_ARN }}
    EKS_CLUSTER_ROLE_ARN: ${{ secrets.EKS_CLUSTER_ROLE_ARN }}
    EKS_SUBNET_IDS: ${{ secrets.EKS_SUBNET_IDS }}
    SEPARATOR: ","
    jobs:
    benchmark_start:
        name: Corbench Start
        if: github.event.action == 'corbench_start'
        runs-on: ubuntu-latest
        steps:
        - name: Update status to pending
            run: >-
            curl -i -X POST
            -H "Authorization: Bearer $GITHUB_TOKEN"
            -H "Content-Type: application/json"
            --data '{"state":"pending",  "context": "corbench-status-update-start", "target_url": "'$GITHUB_STATUS_TARGET_URL'"}'
            "https://api.github.com/repos/$GITHUB_REPOSITORY/statuses/$LAST_COMMIT_SHA"
        - name: Run make deploy to start corbench
            id: make_deploy
            uses: docker://corbench/corbench:latest
            with:
            args: >-
                until make all_nodes_deleted; do echo "waiting for nodepools to be deleted"; sleep 10; done;
                make deploy;
        - name: Update status to failure
            if: failure()
            run: >-
            curl -i -X POST
            -H "Authorization: Bearer $GITHUB_TOKEN"
            -H "Content-Type: application/json"
            --data '{"state":"failure",  "context": "corbench-status-update-start", "target_url": "'$GITHUB_STATUS_TARGET_URL'"}'
            "https://api.github.com/repos/$GITHUB_REPOSITORY/statuses/$LAST_COMMIT_SHA"
        - name: Update status to success
            if: success()
            run: >-
            curl -i -X POST
            -H "Authorization: Bearer $GITHUB_TOKEN"
            -H "Content-Type: application/json"
            --data '{"state":"success",  "context": "corbench-status-update-start", "target_url": "'$GITHUB_STATUS_TARGET_URL'"}'
            "https://api.github.com/repos/$GITHUB_REPOSITORY/statuses/$LAST_COMMIT_SHA"
    benchmark_cancel:
        name: Corbench Cancel
        if: github.event.action == 'corbench_stop'
        runs-on: ubuntu-latest
        steps:
        - name: Update status to pending
            run: >-
            curl -i -X POST
            -H "Authorization: Bearer $GITHUB_TOKEN"
            -H "Content-Type: application/json"
            --data '{"state":"pending",  "context": "corbench-status-update-cancel", "target_url": "'$GITHUB_STATUS_TARGET_URL'"}'
            "https://api.github.com/repos/$GITHUB_REPOSITORY/statuses/$LAST_COMMIT_SHA"
        - name: Run make clean to stop corbench
            id: make_clean
            uses: docker://corbench/corbench:latest
            with:
            args: >-
                until make all_nodes_running; do echo "waiting for nodepools to be created"; sleep 10; done;
                make clean;
        - name: Update status to failure
            if: failure()
            run: >-
            curl -i -X POST
            -H "Authorization: Bearer $GITHUB_TOKEN"
            -H "Content-Type: application/json"
            --data '{"state":"failure",  "context": "corbench-status-update-cancel", "target_url": "'$GITHUB_STATUS_TARGET_URL'"}'
            "https://api.github.com/repos/$GITHUB_REPOSITORY/statuses/$LAST_COMMIT_SHA"
        - name: Update status to success
            if: success()
            run: >-
            curl -i -X POST
            -H "Authorization: Bearer $GITHUB_TOKEN"
            -H "Content-Type: application/json"
            --data '{"state":"success",  "context": "corbench-status-update-cancel", "target_url": "'$GITHUB_STATUS_TARGET_URL'"}'
            "https://api.github.com/repos/$GITHUB_REPOSITORY/statuses/$LAST_COMMIT_SHA"
    ```

    After this change is merged to the upstream branch of the repo, the benchmarking tool should be completely set up!. Give it a try by typing /corbench and following the instructions to start a benchmark test.

    Finally you're done! Congrats on making it to the end of this super long deployment doc and happy benchmarking!


## Starting a Benchmark test locally

### 1. Start a Benchmarking Test Manually
    If you are making changes to benchmark tests, or if you just want to test if benchmark tests can be ran, or if you just want to mess around, you can run them by following the steps below.
---

1. **Set the Environment Variables**:

    Assuming you have all above mentioned env variables already exported in previous steps,

    ```bash
    export RELEASE=<cortex-tag of cortex release for PR to be benchmarked against. List of tags can be found at https://hub.docker.com/r/cortexproject/cortex/tags>
    export PR_NUMBER=<Cortex PR number to benchmark against the selected $RELEASE. Choose an existing corbench pr number. You can find the pr numbers on the repo>
    ```

2. **Start the test**

---

    Run the following command (you should be aware that you need to run make comands in the /corbench directory by now): 

    ```bash
    make deploy
    ```

    Now you can check the grafana dashboards you set up earlier in the deployment to see the results after deployment is finished!

### 2. Stopping and cleaning up Benchmarking Test

---

    Assuming you have previous enviroment variables exported, run

    ```bash
    make clean
    ```
    
