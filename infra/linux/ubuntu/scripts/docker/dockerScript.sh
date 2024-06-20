#!/usr/bin/bash 
#VAN GET.DOCKER.COM GEHAALD
#DOCKER INSTALLER VOOR OP VM
# 1. download the script

sudo curl -fsSL https://get.docker.com -o install-docker.sh

# 2. verify the script's content

#sudo cat install-docker.sh

# 3. run the script with --dry-run to verify the steps it executes

#sudo sh install-docker.sh --dry-run

# 4. run the script either as root, or using sudo to perform the installation.

sudo sh install-docker.sh