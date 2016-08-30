#!/bin/bash
# AUTHOR:   	Roman Kharkovski (https://ibmadvantage.com)

# This must be run on the HTTP server host
echo "Stopping http server..."
sudo /opt/IBM/HTTPServer/bin/apachectl -k stop

if [ $? != 0 ]; then
	echo "!!!!!!!!!! Error while stopping HTTP server !!!!!!!!!!"
else
	echo "HTTP server has been stopped."	
fi