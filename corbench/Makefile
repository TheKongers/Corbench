INFRA_CMD  ?= ./infra/infra
PROVIDER   ?= eks
MANIFEST_FILE = c-manifests

cluster_create:
	${INFRA_CMD} ${PROVIDER} cluster create -a ${AUTH_FILE} \
		-v ZONE:${ZONE} -v GKE_PROJECT_ID:${GKE_PROJECT_ID} \
		-v EKS_WORKER_ROLE_ARN:${EKS_WORKER_ROLE_ARN} -v EKS_CLUSTER_ROLE_ARN:${EKS_CLUSTER_ROLE_ARN} \
		-v EKS_SUBNET_IDS:${EKS_SUBNET_IDS} -v SEPARATOR:${SEPARATOR} \
		-v CLUSTER_NAME:${CLUSTER_NAME} -v PR_NUMBER:${PR_NUMBER} \
		-v AWS_ACCOUNT_ID:$$(echo ${EKS_WORKER_ROLE_ARN} | cut -d':' -f5) \
		-f ${MANIFEST_FILE}/cluster_${PROVIDER}.yaml
ifeq (${PROVIDER},eks)
	./setup-ebs-csi.sh
endif

cluster_resource_apply:
	${INFRA_CMD} ${PROVIDER} resource apply -a ${AUTH_FILE} \
		-v ZONE:${ZONE} -v GKE_PROJECT_ID:${GKE_PROJECT_ID} \
		-v EKS_WORKER_ROLE_ARN:${EKS_WORKER_ROLE_ARN} -v EKS_CLUSTER_ROLE_ARN:${EKS_CLUSTER_ROLE_ARN} \
		-v EKS_SUBNET_IDS:${EKS_SUBNET_IDS} -v SEPARATOR:${SEPARATOR} \
		-v CLUSTER_NAME:${CLUSTER_NAME} -v PR_NUMBER:${PR_NUMBER} -v DOMAIN_NAME:${DOMAIN_NAME} -v RELEASE:${RELEASE} \
		-v GRAFANA_ADMIN_PASSWORD:${GRAFANA_ADMIN_PASSWORD} \
		-v SERVICEACCOUNT_CLIENT_EMAIL:${SERVICEACCOUNT_CLIENT_EMAIL} \
		-v OAUTH_TOKEN="$(printf ${OAUTH_TOKEN} | base64 -w 0)" \
		-v WH_SECRET="$(printf ${WH_SECRET} | base64 -w 0)" \
		-v GITHUB_ORG:${GITHUB_ORG} -v GITHUB_REPO:${GITHUB_REPO} \
		-f ${MANIFEST_FILE}/cluster-infra
	# Patch secrets immediately after deployment with correct values since for some reason 1_secrets isn't working properly
	export AWS_ACCESS_KEY_ID=$$(grep "accesskeyid:" ${AUTH_FILE} | awk '{print $$2}') && \
	export AWS_SECRET_ACCESS_KEY=$$(grep "secretaccesskey:" ${AUTH_FILE} | awk '{print $$2}') && \
	kubectl patch secret oauth-token -p '{"data":{"oauth":"'$$(printf "${OAUTH_TOKEN}" | base64)'"}}' && \
	kubectl patch secret whsecret -p '{"data":{"whsecret":"'$$(printf "${WH_SECRET}" | base64)'"}}' && \
	kubectl rollout restart deployment/comment-monitor

cluster_delete:
	${INFRA_CMD} ${PROVIDER} cluster delete -a ${AUTH_FILE} \
		-v ZONE:${ZONE} -v GKE_PROJECT_ID:${GKE_PROJECT_ID} \
		-v EKS_WORKER_ROLE_ARN:${EKS_WORKER_ROLE_ARN} -v EKS_CLUSTER_ROLE_ARN:${EKS_CLUSTER_ROLE_ARN} \
		-v EKS_SUBNET_IDS:${EKS_SUBNET_IDS} -v SEPARATOR:${SEPARATOR} \
		-v CLUSTER_NAME:${CLUSTER_NAME} -v PR_NUMBER:${PR_NUMBER} \
		-v AWS_ACCOUNT_ID:$$(echo ${EKS_WORKER_ROLE_ARN} | cut -d':' -f5) \
		-f ${MANIFEST_FILE}/cluster_${PROVIDER}.yaml


BENCHMARK_DIRECTORY := $(if $(BENCHMARK_DIRECTORY),$(BENCHMARK_DIRECTORY),c-manifests/benchmarks)

CORBENCH_DIR ?= .

.PHONY: deploy
deploy: node_create resource_apply

.PHONY: clean
clean: resource_delete node_delete

# Default PR_NUMBER to 'default' if not set to avoid invalid nodegroup names
PR_NUMBER ?= default

node_create:
	${INFRA_CMD} ${PROVIDER} nodes create -a ${AUTH_FILE} \
		-v ZONE:${ZONE} -v GKE_PROJECT_ID:${GKE_PROJECT_ID} \
		-v EKS_WORKER_ROLE_ARN:${EKS_WORKER_ROLE_ARN} -v EKS_CLUSTER_ROLE_ARN:${EKS_CLUSTER_ROLE_ARN} \
		-v EKS_SUBNET_IDS:${EKS_SUBNET_IDS} \
		-v CLUSTER_NAME:${CLUSTER_NAME} -v PR_NUMBER:${PR_NUMBER} \
		-f ${CORBENCH_DIR}/${BENCHMARK_DIRECTORY}/nodes_${PROVIDER}.yaml

resource_apply:
	$(INFRA_CMD) ${PROVIDER} resource apply -a ${AUTH_FILE} \
		-v ZONE:${ZONE} -v GKE_PROJECT_ID:${GKE_PROJECT_ID} \
		-v CLUSTER_NAME:${CLUSTER_NAME} \
		-v PR_NUMBER:${PR_NUMBER} -v RELEASE:${RELEASE} -v DOMAIN_NAME:${DOMAIN_NAME} \
		-v GITHUB_ORG:${GITHUB_ORG} -v GITHUB_REPO:${GITHUB_REPO} \
		-f ${CORBENCH_DIR}/${BENCHMARK_DIRECTORY}/remote-write

# Required because namespace and cluster-role are not part of the created nodes
resource_delete:
	$(INFRA_CMD) ${PROVIDER} resource delete -a ${AUTH_FILE} \
		-v ZONE:${ZONE} -v GKE_PROJECT_ID:${GKE_PROJECT_ID} \
		-v CLUSTER_NAME:${CLUSTER_NAME} -v PR_NUMBER:${PR_NUMBER} \
		-f ${CORBENCH_DIR}/${BENCHMARK_DIRECTORY}/remote-write/1c_cluster-role-binding.yaml \
		-f ${CORBENCH_DIR}/${BENCHMARK_DIRECTORY}/remote-write/1a_namespace.yaml

node_delete:
	$(INFRA_CMD) ${PROVIDER} nodes delete -a ${AUTH_FILE} \
		-v ZONE:${ZONE} -v GKE_PROJECT_ID:${GKE_PROJECT_ID} \
		-v EKS_WORKER_ROLE_ARN:${EKS_WORKER_ROLE_ARN} -v EKS_CLUSTER_ROLE_ARN:${EKS_CLUSTER_ROLE_ARN} \
		-v EKS_SUBNET_IDS:${EKS_SUBNET_IDS} \
		-v CLUSTER_NAME:${CLUSTER_NAME} -v PR_NUMBER:${PR_NUMBER} \
		-f ${CORBENCH_DIR}/${BENCHMARK_DIRECTORY}/nodes_${PROVIDER}.yaml

all_nodes_running:
	$(INFRA_CMD) ${PROVIDER} nodes check-running -a ${AUTH_FILE} \
		-v ZONE:${ZONE} -v GKE_PROJECT_ID:${GKE_PROJECT_ID} \
		-v EKS_WORKER_ROLE_ARN:${EKS_WORKER_ROLE_ARN} -v EKS_CLUSTER_ROLE_ARN:${EKS_CLUSTER_ROLE_ARN} \
		-v EKS_SUBNET_IDS:${EKS_SUBNET_IDS} -v SEPARATOR:${SEPARATOR} \
		-v CLUSTER_NAME:${CLUSTER_NAME} -v PR_NUMBER:${PR_NUMBER} \
		-f ${CORBENCH_DIR}/${BENCHMARK_DIRECTORY}/nodes_${PROVIDER}.yaml

all_nodes_deleted:
	$(INFRA_CMD) ${PROVIDER} nodes check-deleted -a ${AUTH_FILE} \
		-v ZONE:${ZONE} -v GKE_PROJECT_ID:${GKE_PROJECT_ID} \
		-v EKS_WORKER_ROLE_ARN:${EKS_WORKER_ROLE_ARN} -v EKS_CLUSTER_ROLE_ARN:${EKS_CLUSTER_ROLE_ARN} \
		-v EKS_SUBNET_IDS:${EKS_SUBNET_IDS} -v SEPARATOR:${SEPARATOR} \
		-v CLUSTER_NAME:${CLUSTER_NAME} -v PR_NUMBER:${PR_NUMBER} \
		-f ${CORBENCH_DIR}/${BENCHMARK_DIRECTORY}/nodes_${PROVIDER}.yaml
