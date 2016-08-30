#!/bin/bash
# from https://docs.docker.com/engine/installation/linux/ubuntulinux/

sudo apt-get update
sudo apt-get install linux-image-extra-$(uname -r)
sudo apt-get install apt-transport-https ca-certificates
sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

echo Open the /etc/apt/sources.list.d/docker.list file in your favorite editor.
echo If the file doesn’t exist, create it as root user.
echo Remove any existing entries.
echo Add an entry for your Ubuntu operating system.
echo deb https://apt.dockerproject.org/repo ubuntu-xenial main
echo ....... we will do it for you now - automatically .....
read -p "Press [Enter] key to continue (this will add 1 line to the '/etc/apt/sources.list.d/docker.list' file) ..."
echo 'deb https://apt.dockerproject.org/repo ubuntu-xenial main' | sudo tee --append /etc/apt/sources.list.d/docker.list

sudo apt-get update
sudo apt-get purge lxc-docker
apt-cache policy docker-engine

sudo apt-get update
sudo apt-get install docker-engine
sudo service docker start
sudo docker run hello-world
sudo systemctl enable docker # enable run on boot