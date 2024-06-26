#!/bin/bash

#CURL ALS DEZE MIST
sudo apt install -y curl

mkdir ~/MK
#INSTALLEER KUBECTL
echo "Kubectl installeren"
sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" -o kubectl
sudo install -o root -g root -m 0755 ~/scripts/kubectl /usr/local/bin/kubectl
sudo chmod +x /usr/local/bin/kubectl   # Zorg ervoor dat kubectl uitvoerbaar is
kubectl version --client

#INSTALLEER MINIKUBE
echo "Minikube installeren"
sudo curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 -o ~/MK/minikube-linux-amd64
sudo install -o root -g root -m 0755 ~/scripts/minikube-linux-amd64 /usr/local/bin/minikube
sudo chmod +x /usr/local/bin/minikube   # Zorg ervoor dat minikube uitvoerbaar is
minikube version


#MINIKUBE STARTEN
echo "Minikube starten"
sudo minikube start --driver=docker

#STATUS MINIKUBE CONTROLEREN
echo "Minikube status checken"
sudo minikube status
