#!/bin/bash
# Agent install
set -euxc
wget -qO - https://packages.fluentbit.io/fluentbit.key | sudo apt-key add -
echo 'deb https://packages.fluentbit.io/ubuntu/focal focal main' | sudo tee -a /etc/apt/sources.list
sudo apt-get update
sudo apt-get install -y td-agent-bit
sudo service td-agent-bit start

git clone https://github.com/k8-proxy/k8-vmware.git
cd k8-vmware
sudo apt-get install -y python3 python3-pip
pip3 install -r requirements.txt
pip3 install -e . 
