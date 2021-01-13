#!/bin/sh
set -eux

sudo sh -c 'echo "vm.max_map_count=262144" > /etc/sysctl.d/20-max_map_count.conf'
sudo sysctl -p

sudo mkdir -p /etc/logtrixia
sudo cp docker-compose.yml /etc/logtrixia/.
sudo cp -R nginx-config /etc/logtrixia/.
sudo cp logtrixia.service /etc/systemd/system/logtrixia.service
sudo systemctl enable logtrixia