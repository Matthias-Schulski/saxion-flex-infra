#!/bin/bash
#VAN GET.DOCKER.COM
# Download het Docker installatiescript van get.docker.com
sudo curl -fsSL https://get.docker.com -o get-docker.sh

# Voer het Docker installatiescript uit
sudo sh get-docker.sh

# Start de Docker service
sudo systemctl start docker

# Optioneel: stel Docker in om automatisch te starten bij het opstarten van het systeem
sudo systemctl enable docker

# Toon de geïnstalleerde Docker versie
docker --version
