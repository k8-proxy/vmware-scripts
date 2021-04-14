#!/bin/bash
source /home/ubuntu/.env
SSH_PASSWORD=${SSH_PASSWORD:-glasswall}
printf $SSH_PASSWORD | base64 | base64
printf "${SSH_PASSWORD}\n${SSH_PASSWORD}" | passwd ubuntu
sed -i "s/.*PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config
service ssh restart
