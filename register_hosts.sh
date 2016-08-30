#!/bin/bash

# AUTHOR:   	Roman Kharkovski (https://ibmadvantage.com)

source setenv.sh
source functions.sh

echo_my "***************************** Begin '$BASH_SOURCE' script..."

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

echo_my "**************************** The '$BASH_SOURCE' script is done. Host registration is complete."