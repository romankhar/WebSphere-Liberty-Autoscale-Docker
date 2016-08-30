# Dockerfile to create a Liberty Network Deployment image 
# This Dockerfile assumes:
# - The collective enabling scripts (joinMember, removeMember) will be placed in
#   /opt/ibm/docker in the Docker container
# - WebSphere Liberty will be installed at /opt/ibm/wlp
# - The WebSphere Liberty server will be "defaultServer"
#   (for example, /opt/ibm/wlp/usr/servers/defaultServer)
# - The Docker container runs using --net=host so that no ports are explicitly exported in this file

FROM websphere-liberty

# Auto-start the Liberty server with the container
ENTRYPOINT ["/opt/ibm/wlp/bin/server", "run", "defaultServer"]

# Add collective enabling scripts
ADD joinMember /opt/ibm/docker/
RUN chmod +x /opt/ibm/docker/joinMember
ADD removeMember /opt/ibm/docker/
RUN chmod +x /opt/ibm/docker/removeMember

# Update the operating system 
RUN apt-get update

# Add the additional required features
RUN installUtility install --acceptLicense localConnector-1.0 monitor-1.0 servlet-3.1 jsp-2.3 scalingMember-1.0 clusterMember-1.0 collectiveMember-1.0
ADD server.xml /opt/ibm/wlp/usr/servers/defaultServer/

# Insert your application file name. This statement copies the application onto the Docker image.
ADD tmp/DriversLicenseApp.war /opt/ibm/wlp/usr/servers/defaultServer/dropins/