#!/bin/bash
sudo apt update
sudo apt install nginx -y
sudo apt install stress -y
sudo rm -rf /var/www/html/*
sudo echo $(hostname --all-ip-addresses) > /var/www/html/index.html
sudo systemctl start nginx