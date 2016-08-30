#!/bin/bash

# Last update: 	August 26, 2016
# AUTHOR:   	Roman Kharkovski (https://ibmadvantage.com)

source ../functions.sh

set -o nounset
set -o errexit

echo_my "Starting conversion of HTTP Server plugin configuration into usable format..." $ECHO_INFO
echo_my "This must be run ONCE on the HTTP server after installing Liberty Controller" $ECHO_INFO
echo_my "PREREQ: before running this, the dynamic routing on the controller must be enabled" $ECHO_INFO

TEMP_PATH=/tmp
FILE1=plugin-key.jks
FILE2=plugin-key.kdb
FILE3=plugin-key.rdb
FILE4=plugin-key.sth
PLUGIN_CONFIG_PATH=${PLUGIN_INSTALL_ROOT}/config
IHS_PATH=/opt/IBM/HTTPServer/bin

sudo rm -rf $TEMP_PATH/$FILE2
sudo rm -rf $TEMP_PATH/$FILE3
sudo rm -rf $TEMP_PATH/$FILE4

if [ ! -d $PLUGIN_CONFIG_PATH/$WEBSERVER_HOST_NAME ]; then
	sudo mkdir $PLUGIN_CONFIG_PATH/$WEBSERVER_HOST_NAME
fi

BACKUP_DIR=$PLUGIN_CONFIG_PATH/$WEBSERVER_HOST_NAME/old
if [ ! -d $BACKUP_DIR ]; then
	sudo mkdir $BACKUP_DIR
fi	

sudo mv $PLUGIN_CONFIG_PATH/$WEBSERVER_HOST_NAME/plugin-cfg.xml $BACKUP_DIR | true		# ignore if there is nothing to backup
sudo mv $PLUGIN_CONFIG_PATH/$WEBSERVER_HOST_NAME/$FILE2 $BACKUP_DIR | true		# ignore if there is nothing to backup
sudo mv $PLUGIN_CONFIG_PATH/$WEBSERVER_HOST_NAME/$FILE3 $BACKUP_DIR | true		# ignore if there is nothing to backup
sudo mv $PLUGIN_CONFIG_PATH/$WEBSERVER_HOST_NAME/$FILE4 $BACKUP_DIR | true		# ignore if there is nothing to backup

sudo cp plugin-cfg.xml $PLUGIN_CONFIG_PATH/$WEBSERVER_HOST_NAME
	 
echo_my "   Generating keystore..." $ECHO_INFO
sudo $IHS_PATH/gskcmd -keydb -convert -pw $KEYSTORE_PASSWORD -db $FILE1 -old_format jks -target $TEMP_PATH/$FILE2 -new_format cms -stash -expire 365
echo_my "   Generating certificates..." $ECHO_INFO
sudo $IHS_PATH/gskcmd -cert -setdefault -pw $KEYSTORE_PASSWORD -db $TEMP_PATH/$FILE2 -label default

sudo cp $TEMP_PATH/$FILE2 $PLUGIN_CONFIG_PATH/$WEBSERVER_HOST_NAME
sudo cp $TEMP_PATH/$FILE3 $PLUGIN_CONFIG_PATH/$WEBSERVER_HOST_NAME
sudo cp $TEMP_PATH/$FILE4 $PLUGIN_CONFIG_PATH/$WEBSERVER_HOST_NAME

echo_my "SUCCESS: HTTP server configuration has been updated." $ECHO_INFO