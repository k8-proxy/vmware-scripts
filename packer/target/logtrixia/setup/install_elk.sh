#!/bin/sh
set -eux

sudo sh -c 'echo "vm.max_map_count=262144" > /etc/sysctl.d/20-max_map_count.conf'
sudo sysctl -p

sudo mkdir -p /etc/logtrixia
sudo cp docker-compose.yml /etc/logtrixia/.
sudo cp -R nginx-config /etc/logtrixia/.
sudo cp logtrixia.service /etc/systemd/system/logtrixia.service
sudo systemctl enable logtrixia
sudo systemctl start logtrixia
sleep 480
curl -X POST --user httpuser:httppass \
-H 'kbn-xsrf: true' -H 'Content-Type: application/json' \
'http://localhost:8881/api/kibana/dashboards/import' \
-d @dashboard/healthcheck.json