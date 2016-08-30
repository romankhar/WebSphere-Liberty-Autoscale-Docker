source ../setenv.sh

mkdir tmp
cp ../apps/2_DriversLicenseApp.war tmp/DriversLicenseApp.war

# Build docker image
docker build -t $DOCKER_IMAGE_NAME .

# List available docker images
docker images

# Cleanup
rm -rf tmp