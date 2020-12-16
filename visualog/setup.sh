#!/bin/bash

# This is a placeholder script, you can move your setup script here to install some custom deployment on the VM
# The parent directory of this script will be transferred with its content to the VM under /tmp/setup path
# (i.e: useful for copying configs, scripts, systemd units, etc..)  
git clone --single-branch --depth 1 https://github.com/k8-proxy/vmware-scripts.git
cd vmware-scripts/visualog/automation
sh install_elk.sh
sh install_kibana.sh
sh install_prometheus.sh
sh install_grafana.sh
cd
rm -rf vmware-scripts
