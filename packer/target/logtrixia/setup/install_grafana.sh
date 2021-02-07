#!/bin/sh
set -eux

sudo mkdir -p /etc/grafana
sudo cp -R grafana/. /etc/grafana/.

sudo cp grafana.service /etc/systemd/system/grafana.service
sudo systemctl daemon-reload
sudo systemctl enable grafana
sudo systemctl start grafana