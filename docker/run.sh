# Run specific docker image

source ../setenv.sh
echo "This will simply run Docker container, but in order to get cluster member running you must use 'deploy.sh' command, otherwise server.xml variables wont be generated dynamically"
docker run --net=host $DOCKER_IMAGE_NAME