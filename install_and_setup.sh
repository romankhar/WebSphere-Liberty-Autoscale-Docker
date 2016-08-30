#!/bin/bash

# This script is run first to install and setup Liberty Controller. Lberty binaries must be downloaded in advance. 
# Location of those binaries is set in the $LIBERTY_DISTRO variable below.
# AUTHOR:   	Roman Kharkovski (https://ibmadvantage.com)

# Some useful tips about error checking in bash found here: http://www.davidpashley.com/articles/writing-robust-shell-scripts/
# This prevents running the script if any of the variables have not been set
set -o nounset
# This automatically exits the script if any error occurs while running it
set -o errexit

source functions.sh
echo_my "Starting installation and configuration of a Liberty Controller..." 

DISTRO_PATH=${PROJECT_HOME}_downloads
LOCAL_REPOSITORY=$DISTRO_PATH/repository
LIBERTY_DISTRO=$DISTRO_PATH/wlp-webProfile7-java8-linux-x86_64-16.0.0.2.zip

# features to be installed
FEATURE_LIST="adminCenter-1.0 localConnector-1.0 collectiveMember-1.0 scalingController-1.0 scalingMember-1.0 clusterMember-1.0 dynamicRouting-1.0 collectiveController-1.0"

echo_my "Stop servers before doing new installation..." 
# stop_all_servers | true
stop_controller | true
my_pause

echo_my "Check for existing server directory..." 
if [ -d "$LIBERTY_HOME" ]; then
	BACKUP_LIBERTY=${LIBERTY_HOME}_bak_`date +%s`
	echo_my "Directory $LIBERTY_HOME already exists - this script will move it to the backup path '$BACKUP_LIBERTY' and install new Liberty image"  $ECHO_WARNING
	mv -f $LIBERTY_HOME $BACKUP_LIBERTY
fi

echo_my "Remove all existing servers..." 
BACKUP_DIR=${WLP_USER_DIR}_`date +%s`
echo_my "Rename old server directory into $BACKUP_DIR ..." 
if [ -d $WLP_USER_DIR ]; then
	mv -f $WLP_USER_DIR $BACKUP_DIR
fi	
mkdir $WLP_USER_DIR
my_pause

echo_my "Installing WAS Liberty..." 
unzip $LIBERTY_DISTRO -d $LIBERTY_PARENT_HOME

if [ ! -d "${LOCAL_REPOSITORY}" ]; then
	echo_my "Local repository is not found at this location: ${LOCAL_REPOSITORY}, proceeding with features download..." 
	mkdir $LOCAL_REPOSITORY
	${LIBERTY_HOME}/bin/installUtility download $FEATURE_LIST --location=$LOCAL_REPOSITORY
fi

# Proceed with the rest of the install
create_repository_configuration
yes 1 | ${LIBERTY_HOME}/bin/installUtility install $FEATURE_LIST
my_pause

# Create Liberty controller
create_controller
my_pause

start_controller
my_pause

echo_my "Register all other hosts for future auto-scaling..." 
register_hosts
my_pause

# enable dynamic routing between HTTP server and the Liberty collective
configure_dynamic_routing
echo_my "To configure HTTP server, please install one on host ${WEBSERVER_HOST_NAME}, then mount this directory there and run the script 'http/config.sh'." 

echo_my "SUCCESS: Installation is complete." 