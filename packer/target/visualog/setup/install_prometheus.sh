#!/bin/sh
set -eux

PROMETHEUS_VERSION=prometheus-2.23.0.linux-amd64
id -u prometheus &>/dev/null || sudo useradd -M -r -s /bin/false prometheus
sudo mkdir -p /etc/prometheus /var/lib/prometheus
wget "https://github.com/prometheus/prometheus/releases/download/v2.23.0/$PROMETHEUS_VERSION.tar.gz"
tar xzf $PROMETHEUS_VERSION.tar.gz
sudo cp $PROMETHEUS_VERSION/prometheus /usr/local/bin/
sudo cp $PROMETHEUS_VERSION/promtool /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool
sudo cp -r $PROMETHEUS_VERSION/consoles /etc/prometheus/
sudo cp -r $PROMETHEUS_VERSION/console_libraries /etc/prometheus/
sudo cp $PROMETHEUS_VERSION/prometheus.yml /etc/prometheus/
sudo chown -R prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus
sudo cp prometheus.service /etc/systemd/system/prometheus.service
sudo systemctl daemon-reload
sudo systemctl enable --now prometheus
sudo systemctl status prometheus --no-pager