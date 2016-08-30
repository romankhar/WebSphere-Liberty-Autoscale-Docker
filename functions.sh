#!/bin/bash

# AUTHOR:   	Roman Kharkovski (https://ibmadvantage.com)
# DESCRIPTION: 	Shared reusable generic functions for the entire project

# Some useful tips about error checking in bash found here: http://www.davidpashley.com/articles/writing-robust-shell-scripts/
# This prevents running the script if any of the variables have not been set
set -o nounset

# This automatically exits the script if any error occurs while running it
#set -o errexit

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/setenv.sh

ECHO_NONE=0
ECHO_NO_PREFIX=1
ECHO_ERROR=1
ECHO_WARNING=2
ECHO_INFO=3
ECHO_DEBUG=4
ECHO_LEVEL=$ECHO_DEBUG

##############################################################################
# Replace standard ECHO function with custom output
# Params:
# 1 - Text to show
# 2 - Type of output (optional) - ERROR, WARNING, INFO
##############################################################################
echo_my()
{
#	PREFIX="(`hostname`:$(basename $0)) "
	PREFIX="[`hostname`] "
	if [ $# -gt 1 ]; then
		ECHO_REQUESTED=$2
	else
		ECHO_REQUESTED=$ECHO_INFO
	fi

	if [ $ECHO_REQUESTED -gt $ECHO_LEVEL ]; then
		# in this case no output shall be produced
		return
	fi

	if [ $ECHO_REQUESTED = $ECHO_ERROR ]; then
		PREFIX="[ERROR] ${PREFIX} "
	fi

	if [ $ECHO_REQUESTED = $ECHO_WARNING ]; then
		PREFIX="[WARNING] ${PREFIX} "
	fi

	if [ $ECHO_REQUESTED = $ECHO_INFO ]; then
		PREFIX="[INFO] ${PREFIX} "
	fi

	if [ $ECHO_REQUESTED = $ECHO_DEBUG ]; then
		PREFIX="[DEBUG] ${PREFIX} "
	fi

	if [ $ECHO_REQUESTED = $ECHO_NO_PREFIX ]; then
		PREFIX=""
	fi

	echo "${PREFIX}$1"
}

##############################################################################
# Custom PAUSE function - can be turned on and off globally
##############################################################################
my_pause()
{
	#	read -p "Press [Enter] key to continue..."
	test=""	# no op - do nothing
}

#############################################
# Create new JVM properties file
# Params:
# 1 - jvm.options fully qualified file name
# 2 - server name
#############################################
CreateJVMoptionsFile() {
	echo_my "Create file $1 with server name $2"
	rm -f $1 | true 	# ignore the error if there is one as it is not critical
	cat << EOF > $1
-DmyServerName=$2
-Dcom.ibm.websphere.collective.utility.autoAcceptCertificates=true
-Dcom.ibm.websphere.dynamicRouting.utility.autoAcceptCertificates=true
-DLIBERTY_AUTO_SCALING_CLUSTER_INJECTION=true
EOF
}

#############################################
# Create server.env file
# Params:
# 1 - server.env fully qualified file name
# 2 - server index number
#############################################
CreateServerEnvFile() {
	echo_my "Creating file $1 ..."
	set_HTTP_PORTS $2
	rm -f $1
	cat << EOF > $1
HTTP_PORT=$HTTP_PORT
HTTPS_PORT=$HTTPS_PORT
HOST_SCALING_PORT=$HOST_SCALING_PORT
CLUSTER_NAME=${CLUSTER_PREFIX}_$2
APP_DEPLOY_DIR=$APP_DEPLOY_DIR
EOF
}

#############################################
# Create server.env file for controller
# Params:
# 1 - server.env fully qualified file name
#############################################
CreateControllerEnvFile() {
	echo_my "Creating controller environment file $1 ..." 
	rm -f $1
	cat << EOF > $1
CONTROLLER_HTTP_PORT=$CONTROLLER_HTTP_PORT
CONTROLLER_PORT=$CONTROLLER_PORT
CLUSTER_PREFIX=$CLUSTER_PREFIX
DYNAMIC_ROUTING_PORT=$DYNAMIC_ROUTING_PORT
ADMIN_USER=$ADMIN_USER
ADMIN_PASSWORD=$ADMIN_PASSWORD
HTTP_PORT_BASE=$HTTP_PORT_BASE
HTTPS_PORT_BASE=$HTTPS_PORT_BASE
EOF
}

#############################################
# Create stack group properties file for controller for auto-scaling
# Params:
# 1 - path to the Liberty Home directory
#############################################
CreateDockerPackagePropFile() {
	echo_my "Creating stack group control file at the path $1 ..." 
	mkdir $1/shared
	mkdir $1/shared/stackGroups
	mkdir $1/shared/stackGroups/${STACK_GROUP}
	mkdir $1/shared/stackGroups/${STACK_GROUP}/packages
	thisFile=$1/shared/stackGroups/${STACK_GROUP}/packages/${PACKAGE_NAME}.deploy.xml
	rm -f $thisFile
	cat << EOF > $thisFile
<deploy>
   <useRule id="Liberty Docker Rule" />
   <variable name="imageName" value="${DOCKER_IMAGE_NAME}" />
   <variable name="containerName" value="${CONTAINER_NAME}" />
   <variable name="clusterName" value="${CLUSTER_PREFIX}" />
   <variable name="keystorePassword" value="${KEYSTORE_PASSWORD}" />
</deploy>
EOF
}

###############################################
# Builds and returns server name into stdout
# Params:
# 1 - Host name
# 2 - Server number
###############################################
server_name()
{
	echo ${1}_server$2
}

###############################################
# Generate dynamic routing configuration on the controller host
###############################################
configure_dynamic_routing()
{
	echo_my "configure_dynamic_routing()..." 
	HOSTNAME=`hostname`
	TMP_WEB_PLUGIN_DIR=http
	if [[ $HOSTNAME == $CONTROLLER_HOST_NAME ]]; then
		if [ ! -d $TMP_WEB_PLUGIN_DIR ]; then
			mkdir $TMP_WEB_PLUGIN_DIR
		fi
		CWD=$(pwd)								# save current directory
		cd $TMP_WEB_PLUGIN_DIR					# we want all generated plugin files to go there
		$LIBERTY_HOME/bin/dynamicRouting setup --port=$DYNAMIC_ROUTING_PORT --host=$CONTROLLER_HOST_NAME --user=$ADMIN_USER --password=$ADMIN_PASSWORD --keystorePassword=$KEYSTORE_PASSWORD --pluginInstallRoot=$PLUGIN_INSTALL_ROOT --webServerNames=$WEBSERVER_HOST_NAME
		cd $CWD									# return back to the previous working directory
	else
		echo_my "dynamic routing needs to be called on the host controller '$CONTROLLER_HOST_NAME', while this is host '$HOSTNAME'" $ECHO_WARNING
	fi
}

###############################################
# Create HTTP port number based on server index
# Params:
# 	1 - Server index (i.e. server #1, 2, 3, etc.
# Returns:
# 	HTTP_PORT - variable is set
# 	HTTPS_PORT - variable is set
###############################################
set_HTTP_PORTS()
{
	echo_my "assign HTTP ports for server index $1" 
	HTTP_PORT=`expr $HTTP_PORT_BASE + $1`
	HTTPS_PORT=`expr $HTTPS_PORT_BASE + $1`
	echo_my "HTTP_PORT=$HTTP_PORT, HTTPS_PORT=$HTTPS_PORT" 
}

###############################################
# Starts controller server
###############################################
start_controller()
{
	echo_my "start_controller($CONTROLLER_SERVER_NAME)..." 
	HOSTNAME=`hostname`
	if [[ $HOSTNAME == $CONTROLLER_HOST_NAME ]]; then
		$LIBERTY_HOME/bin/server start $CONTROLLER_SERVER_NAME
	else
		echo_my "controller must be started on the host '$CONTROLLER_HOST_NAME'. This is host '$HOSTNAME'" $ECHO_WARNING
	fi
}

###############################################
# Stop controller server
###############################################
stop_controller()
{
	echo_my "stop_controller($CONTROLLER_SERVER_NAME)..." 
	HOSTNAME=`hostname`
	if [[ $HOSTNAME == $CONTROLLER_HOST_NAME ]]; then
		$LIBERTY_HOME/bin/server stop $CONTROLLER_SERVER_NAME
	else
		echo_my "controller must be stopped on the host '$CONTROLLER_HOST_NAME'. This is host '$HOSTNAME'" $ECHO_WARNING
	fi
}

###############################################
# Create new controller (defined in setenv.sh)
###############################################
create_controller()
{
	SERVER_NAME=$CONTROLLER_SERVER_NAME
	echo_my "create_controller($SERVER_NAME)..." 
	HOSTNAME=`hostname`
	if [[ $HOSTNAME == $CONTROLLER_HOST_NAME ]]; then
		# First we check for existing server directory
		if [ -d "$WLP_USER_DIR/servers/$SERVER_NAME" ]; then
			echo_my "the controller $SERVER_NAME already exists. Try removing it first." $ECHO_WARNING
		else
			echo_my "Create new server definition..." 
			$LIBERTY_HOME/bin/server create $SERVER_NAME
	
			CreateJVMoptionsFile $WLP_USER_DIR/servers/$SERVER_NAME/jvm.options $SERVER_NAME

			CreateControllerEnvFile $WLP_USER_DIR/servers/$SERVER_NAME/server.env

			echo_my "Create new collective configuration..." 
			$LIBERTY_HOME/bin/collective create $SERVER_NAME --keystorePassword=$KEYSTORE_PASSWORD --createConfigFile=$WLP_USER_DIR/servers/$SERVER_NAME/collective-create-include.xml

			CreateDockerPackagePropFile $WLP_USER_DIR
	
			echo_my "Copy server definition into the config dir..." 
			cp server_collective_controller.xml $WLP_USER_DIR/servers/$SERVER_NAME/server.xml
		fi		
	else
		echo_my "Collective controller needs to be called on the host controller '$CONTROLLER_HOST_NAME'. This is host '$HOSTNAME'" $ECHO_WARNING
	fi
}

###############################################
# Create property file for repository configuration
###############################################
create_repository_configuration()
{
	echo_my "create_repository_configuration()..." 
	if [ ! -d ${LIBERTY_HOME}/etc ]; then
		mkdir ${LIBERTY_HOME}/etc
	fi
	cat << EOF > ${LIBERTY_HOME}/etc/repositories.properties
useDefaultRepository=false
roman-rep.url=file://${LOCAL_REPOSITORY}
EOF
}

###############################################
# Register remote hosts to the Collective Controller
###############################################
register_hosts()
{
	echo_my "register_hosts()..." 
	if [[ `hostname` != $CONTROLLER_HOST_NAME ]]; then
		echo_my "Error: this script must be run on host $CONTROLLER_HOST_NAME" $ECHO_WARNING
		exit
	fi

	# Provision Controller host for auto-scale
	echo_my "Updating controller RPC for auto-scale..."
	$LIBERTY_HOME/bin/collective updateHost ${CONTROLLER_HOST_NAME} --host=${CONTROLLER_HOST_NAME} --port=${CONTROLLER_PORT} --user=${ADMIN_USER} --password=${ADMIN_PASSWORD} --rpcUser=${RPC_USER} --rpcUserPassword=${RPC_PASSWORD}

	# Register all hosts with the controller for auto-scaling operations
	for HOST in $LIST_OF_HOSTS
	do
		echo_my "Registering ${HOST} with the controller on ${CONTROLLER_HOST_NAME}..."
		$LIBERTY_HOME/bin/collective registerHost ${HOST} --host=${CONTROLLER_HOST_NAME} --port=${CONTROLLER_PORT} --user=${ADMIN_USER} --password=${ADMIN_PASSWORD} --rpcUser=${RPC_USER} --rpcUserPassword=${RPC_PASSWORD}
		if [ $? != 0 ]; then
			ERROR="!!!!!!!!!! Error while registering $HOST with the controller on host ${CONTROLLER_HOST_NAME} !!!!!!!!!!!"
			echo_my "${ERROR}" $ECHO_ERROR
		fi
	done
}

###############################################
# Starts a server
# Params:
# 1 - Host name
# 2 - Server number
###############################################
# start_server()
# {
# 	SERVER_NAME=`server_name $1 $2`
# 	echo_my "start_server($SERVER_NAME) ..." 
# 	HOSTNAME=`hostname`
# 	if [[ $HOSTNAME == $1 ]]; then
# 		$LIBERTY_HOME/bin/server start $SERVER_NAME
# 	else
# 		echo_my "Error: host '$HOSTNAME' does not have the server '$SERVER_NAME'" $ECHO_WARNING
# 	fi
# }

###############################################
# Stops a server
#
# Parameters
# 1 - server name
###############################################
# stop_server()
# {
# 	echo_my "stop_server $1" 
# 	$LIBERTY_HOME/bin/server stop $1
# }

###############################################
# Create new server
#
# Parameters
# 1 - Host name
# 2 - Server number
###############################################
# create_server()
# {
# 	SERVER_NAME=`server_name $1 $2`
# 	echo_my "create_server($SERVER_NAME)..." 
		
# 	# First we check for existing server directory
# 	if [ -d "$WLP_USER_DIR/servers/$SERVER_NAME" ]; then
# 		echo_my "server $SERVER_NAME already exists. Try removing it first." $ECHO_WARNING
# 	else
# 		echo_my "start controller because we will need it later..." 
# 		start_controller
	
# 		echo_my "remove existing server even if it exists..." 
# 		remove_server $SERVER_NAME

# 		echo_my "create new server definition..." 
# 		$LIBERTY_HOME/bin/server create $SERVER_NAME
	
# 		echo_my "create jvm properties file..." 
# 		CreateJVMoptionsFile $WLP_USER_DIR/servers/$SERVER_NAME/jvm.options $SERVER_NAME
	
# 		echo_my "create server environment..." 
# 		CreateServerEnvFile $WLP_USER_DIR/servers/$SERVER_NAME/server.env $2
	
# 		echo_my "make this server be part of collective..." 
# 		$LIBERTY_HOME/bin/collective join $SERVER_NAME --host=$CONTROLLER_HOST_NAME --port=$CONTROLLER_PORT --user=$ADMIN_USER --password=$ADMIN_PASSWORD --keystorePassword=$KEYSTORE_PASSWORD --createConfigFile=$WLP_USER_DIR/servers/$SERVER_NAME/collective-member-include.xml
	
# 		echo_my "copy collective definition into the config dir..." 
# 		cp server_collective_member.xml $WLP_USER_DIR/servers/$SERVER_NAME/server.xml
# 	fi
# }

###############################################
# Remove existing server
#
# Parameters
# 1 - server name
###############################################
# remove_server()
# {
# 	SERVER_NAME=$1
# 	echo_my "remove_server($SERVER_NAME)..." 
	
# 	HOSTNAME=`hostname`
# 	if grep -q $HOSTNAME <<<$1; then
# 		# check for existing server directory
# 		if [ -d "$WLP_USER_DIR/servers/$SERVER_NAME" ]; then
# 			echo_my "remove existing server from the collective..." 
# 			$LIBERTY_HOME/bin/collective remove $SERVER_NAME --host=$CONTROLLER_HOST_NAME --port=$CONTROLLER_PORT --user=$ADMIN_USER --password=$ADMIN_PASSWORD

# 			echo_my "stop the server..." 
# 			stop_server $1
	
# 			BACKUP_DIR=/tmp/${SERVER_NAME}_`date +%s`
# 			echo_my "rename old server directory into $BACKUP_DIR ..." 
# 			mv $WLP_USER_DIR/servers/$SERVER_NAME $BACKUP_DIR
# 		else
# 			echo_my "Nothing to do - the server $SERVER_NAME does not exist on host '$HOSTNAME'"  
# 		fi
# 	else
# 			echo_my "Error: the server '$SERVER_NAME' is not defined for host '$HOSTNAME'..."  $ECHO_ERROR
# 	fi
# }

###############################################
# Create all servers
###############################################
# create_all_servers()
# {
# 	echo_my "create_all_servers()..." 	
# 	start_controller
	
# 	for HOST in $LIST_OF_HOSTS
# 	do
# 		for SERVER_INDEX in $LIST_OF_SERVERS
# 		do
#         			create_server $HOST $SERVER_INDEX
#         			if [ $? != 0 ]; then
#         				ERROR="!!!!!!!!!! Error while creating server $SERVER_INDEX on host $HOST"
#         				echo_my "$ERROR"  $ECHO_ERROR
# 					fi
#    		done  
# 	done
# }

###############################################
# Remove all servers
###############################################
# remove_all_servers()
# {
# 	echo_my "remove_all_servers()..." 
# 	#	start_controller
	
# 	for HOST in $LIST_OF_HOSTS
# 	do
# 		for SERVER_INDEX in $LIST_OF_SERVERS
# 		do
# 			SERVER_NAME=`server_name $HOST $SERVER_INDEX`
# 			remove_server $SERVER_NAME
#         	if [ $? != 0 ]; then
#         		ERROR="!!!!!!!!!! Error while removing server $SERVER_INDEX on host $HOST"
#         		echo_my "${ERROR}" $ECHO_ERROR
# 			fi
#    		done  
# 	done
# }

###############################################
# Deploy all apps to all servers on this host
###############################################
# deploy_app()
# {
# 	echo_my "deploy_app()..." 
# 	# mkdir $APP_DEPLOY_DIR
# 	HOSTNAME=`hostname`
	
# 	# ------------------ this deploys all apps into all servers
# 	#for SERVER_INDEX in $LIST_OF_SERVERS
# 	#do
# 	#	SERVER_NAME=`server_name $HOSTNAME $SERVER_INDEX`
# 	#	cp apps/*.war $WLP_USER_DIR/servers/$SERVER_NAME/dropins
# 	#done  
	
# 	# ------------------ this deploys apps into servers where index of the server is the same as the first number on the app file name, followed by "_" sign
# 	for SERVER_INDEX in $LIST_OF_SERVERS
# 	do
# 		SERVER_NAME=`server_name $HOSTNAME $SERVER_INDEX`
# 		cp apps/${SERVER_INDEX}_*.war $WLP_USER_DIR/servers/$SERVER_NAME/dropins
# 	done  
	
# 		echo_my "--------- This Liberty installation is ready to serve client traffic to local ports (AFTER servers are all STARTED):" 
# 	for SERVER_INDEX in $LIST_OF_SERVERS
# 	do
# 		set_HTTP_PORTS $SERVER_INDEX
# 		echo_my "http://localhost:$HTTP_PORT/DriversLicenseApp/Servlet1" 
# 		echo_my "http://localhost:$HTTP_PORT/TaxPaymentApp/Servlet1" 
# 		echo_my "http://localhost:$HTTP_PORT/DisasterResponseApp/Servlet1" 
# 	done  
# }

###############################################
# Un-Deploy all apps to all servers on this host
###############################################
# undeploy_app()
# {
# 	echo_my "deploy_app()..." 
# 	mkdir $APP_DEPLOY_DIR
# 	HOSTNAME=`hostname`
	
# 	for SERVER_INDEX in $LIST_OF_SERVERS
# 	do
# 		SERVER_NAME=`server_name $HOSTNAME $SERVER_INDEX`
# 		rm -f $WLP_USER_DIR/servers/$SERVER_NAME/dropins/*.war
# 	done  
# }

#############################################
# Create server.env file for use in building Docker image
#
# Parameters
# 1 - server.env fully qualified file name
#############################################
# CreateServerEnvDockerFile() {
# 	echo_my "Creating file $1 ..."
# 	rm -f $1
# 	cat << EOF > $1
# HOST_SCALING_PORT=$HOST_SCALING_PORT
# EOF
# 	echo_my "<------"
# }