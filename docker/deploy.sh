#!/bin/bash

# This script allows one to manually deploy new Docker containers in a Liberty Collective environment using Controller REST API
# Based on the InfoCenter article: 
# http://www.ibm.com/support/knowledgecenter/SSAW57_liberty/com.ibm.websphere.wlp.nd.doc/ae/twlp_deployservice_docker.html

source ../setenv.sh 

# Define common command to be reused later
COMMAND="--verbose --insecure -u ${ADMIN_USER}:${ADMIN_PASSWORD} https://${CONTROLLER_HOST_NAME}:${CONTROLLER_PORT}/ibm/api/collective/v1/deployment"
TARGET_HOST=host1
JSON_FILE=docker_deploy.json

# ------------------------------------------------------------------------------
# deploy new remote docker instance
echo "{
	\"rule\": \"Liberty Docker Rule\",
	\"hosts\": [\"${TARGET_HOST}\"],
	\"variables\": [{
		\"name\": \"imageName\",
		\"value\": \"${DOCKER_IMAGE_NAME}\"
	}, {
		\"name\": \"containerName\",
		\"value\": \"${CONTAINER_NAME}\"
	}, {
		\"name\": \"clusterName\",
		\"value\": \"${CLUSTER_PREFIX}\"
	}, {
		\"name\": \"keystorePassword\",
		\"value\": \"${KEYSTORE_PASSWORD}\"
	}]
}" > ${JSON_FILE}
#curl -X POST --header "Content-Type: application/json" --data @${JSON_FILE} ${COMMAND}/deploy

# ------------------------------------------------------------------------------
#Get the complete results of a deployment operation. Use the token from step 4 for {token}. Thus, for a {"id":3} return token from step 4, use 3 for {token}.
curl ${COMMAND}/3/results

# ------------------------------------------------------------------------------
# read current deployment rules. To diagnose issues, use flag: 'curl --verbose'
#curl ${COMMAND}/rule

# ------------------------------------------------------------------------------
#Get a list of tokens for requested deployment operations.
#curl ${COMMAND}/deploy

# ------------------------------------------------------------------------------
#Get a short status of the deployment operations. Use the token from step 4 for {token}. Thus, for a {"id":3} return token from step 4, use 3 for {token}.
#curl ${COMMAND}/1/status

# ------------------------------------------------------------------------------
# Undeploy a container.
#echo "{ \"host\": \"${TARGET_HOST}\", \"userDir\":\"Docker\", \"serverName\":\"${CONTAINER_NAME}\" }" > ${JSON_FILE}
#curl -X POST --header "Content-Type: application/json" --data @${JSON_FILE} ${COMMAND}/undeploy

# ------------------------------------------------------------------------------
#Get a list of tokens for undeployment operations.
#curl ${COMMAND}/undeploy

# Cleanup
rm ${JSON_FILE}
