#!/bin/sh
set -eux

sudo sh -c 'echo "vm.max_map_count=262144" > /etc/sysctl.d/20-max_map_count.conf'
sudo sysctl -p
sudo docker-compose up -d
