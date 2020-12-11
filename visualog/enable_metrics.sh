#!/bin/sh

sudo su -
git clone https://github.com/k8-proxy/vmware-scripts
cd visualog
wget https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz
tar xvzf node_exporter-1.0.1.linux-amd64.tar.gz
cp node_exporter-1.0.1.linux-amd64/node_exporter /usr/sbin/
useradd node_exporter -s /sbin/nologin
cp monitoring-scripts/node_exporter.service /etc/systemd/system/
mkdir -p /etc/prometheus
cp monitoring-scripts/node_exporter.config /etc/prometheus/node_exporter.config
systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter
systemctl status node_exporter