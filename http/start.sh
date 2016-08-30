#!/bin/bash 

# This must be run on the HTTP server host
echo "Starting http server..."
sudo /opt/IBM/HTTPServer/bin/apachectl -k start

if [ $? != 0 ]; then
	echo "!!!!!!!!!! Error while starting HTTP server !!!!!!!!!!"
else
	echo "HTTP server has been started."	
fi