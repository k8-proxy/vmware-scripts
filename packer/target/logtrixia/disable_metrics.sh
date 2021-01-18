#!/bin/sh

set -eux

systemctl stop node_exporter
systemctl disable node_exporter
rm /etc/systemd/system/node_exporter.service
userdel node_exporter
rm /usr/sbin/node_exporter
rm -rf /etc/prometheus/
rm -rf vmware-scripts
systemctl daemon-reload