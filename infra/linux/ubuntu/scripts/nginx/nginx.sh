#!/usr/bin/bash
#NGINX INSTALLER VOOR OP VM

# NGINX INSTALLEREN
sudo apt install -y nginx

# NGINX STARTEN
sudo systemctl start nginx

# NGINX ENABLEN
sudo systemctl enable nginx

# STATUS NGINX CHECKEN
sudo systemctl status nginx
