#!/bin/sh
set -eux
export $(cat elastic/.env | xargs)

sudo sh -c 'echo "vm.max_map_count=262144" > /etc/sysctl.d/20-max_map_count.conf'
sudo sysctl -p

sudo mkdir -p /etc/logtrixia
sudo cp elastic/.env /etc/logtrixia/.env

sudo cp -R elastic/certificates /etc/logtrixia/certificates
sudo cp -R elastic/utils /etc/logtrixia/utils
sudo cp elastic/elastic-docker-tls.yml /etc/logtrixia/.
sudo cp -R nginx-config /etc/logtrixia/.
sudo cp logtrixia.service /etc/systemd/system/logtrixia.service
sudo systemctl daemon-reload
sudo systemctl enable logtrixia
sudo systemctl start logtrixia