#!/bin/bash

sudo mkdir /var/log/couples_questions_backend
sudo chown williwacker:williwacker /var/log/couples_questions_backend
sudo cp puma.service /etc/systemd/system/
sudo cp sidekiq.service /etc/systemd/system/
sudo cp rails.conf /etc/
sudo chown williwacker:williwacker /etc/rails.conf
sudo chmod 400 /etc/rails.conf
# set MYSQL_ADMIN_PASSWORD, etc in rails.conf

# set 640 permissions for fcm key files

sudo systemctl daemon-reload
sudo systemctl enable puma
sudo systemctl enable sidekiq
sudo systemctl start puma
sudo systemctl start sidekiq
