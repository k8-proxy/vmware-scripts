#!/bin/sh
set -eux
export $(cat elastic/.env | xargs)

sudo sh -c 'echo "vm.max_map_count=262144" > /etc/sysctl.d/20-max_map_count.conf'
sudo sysctl -p

sudo mkdir -p /etc/logtrixia
sudo cp elastic/.env /etc/logtrixia/.env

printenv

echo "Configuring certificates"
cd elastic
sudo docker-compose -f create-certs.yml run --rm create_certs
cd ..

sudo cp elastic/elastic-docker-tls.yml /etc/logtrixia/.

sudo cp logtrixia.service /etc/systemd/system/logtrixia.service
sudo systemctl daemon-reload
sudo systemctl enable logtrixia
sudo systemctl start logtrixia