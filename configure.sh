#!/bin/bash

# nginx

# check for nginx config file and create a backup if exist
if [ -f "/etc/nginx/nginx.conf" ]; then
    sudo mv /etc/nginx/nginx.conf /etc/nginx/nginx.backup.conf
    sudo mv ./nginx.conf /etc/nginx/nginx.conf
else
    sudo mv ./nginx.conf /etc/nginx/nginx.conf
fi

mkdir /hls
chown www-data:www-data /hls
chmod 777 /hls

# bucket
chmod +x ./observer.sh
sudo mv ./observer.sh /usr/bin/observer.sh

# ffmpeg
chmod +x ./connection.sh
sudo mv ./connection.sh /usr/bin/connection.sh

# Services
sudo mv ./observer.service /etc/systemd/system/observer.service
sudo mv ./connection.service /etc/systemd/system/connection.service
sudo systemctl daemon-reload
sudo systemctl enable observer.service
sudo systemctl enable connection.service
