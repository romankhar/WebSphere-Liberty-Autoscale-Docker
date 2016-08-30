#!/bin/bash

# AUTHOR:   	Roman Kharkovski (https://ibmadvantage.com)

# Project location - this is where this script is located
PROJECT_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Install paths
LIBERTY_PARENT_HOME=/home/roman/liberty
export LIBERTY_HOME=${LIBERTY_PARENT_HOME}/wlp
export JAVA_HOME=${LIBERTY_HOME}/java/java
export PATH=${PATH}:${JAVA_HOME}/bin
export JVM_ARGS="-Dcom.ibm.websphere.collective.utility.autoAcceptCertificates=true -Dcom.ibm.websphere.dynamicRouting.utility.autoAcceptCertificates=true"
export WLP_USER_DIR=/home/roman/liberty_user_servers

# This install path points to the plugin install directory on the HTTP server when running contoller command to generate plugin config
PLUGIN_INSTALL_ROOT=/opt/IBM/WebSphere/Plugins

# Host names
CONTROLLER_SERVER_NAME=host1_controller
CONTROLLER_HOST_NAME=host1
WEBSERVER_HOST_NAME=httphost
LIST_OF_HOSTS="host2 host3"

# Ports
CONTROLLER_HTTP_PORT=9080
CONTROLLER_PORT=9443
DYNAMIC_ROUTING_PORT=9444
HOST_SCALING_PORT=5164
# Starting number for the port assignment for Liberty servers
HTTP_PORT_BASE=9090
HTTPS_PORT_BASE=9453

# Cluster names
STACK_GROUP=rkStackGroup
PACKAGE_NAME=rkCluster
CLUSTER_PREFIX=${STACK_GROUP}.${PACKAGE_NAME}

# Collective controller user
ADMIN_USER=roman
ADMIN_PASSWORD=password
KEYSTORE_PASSWORD=passw0rd

# User info for using SSH into remote hosts
RPC_USER=roman
RPC_PASSWORD=goodsmaker

# Docker specific configuration
DOCKER_IMAGE_NAME=liberty_img
CONTAINER_NAME=g6_Liberty