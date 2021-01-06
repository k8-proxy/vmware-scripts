#!/bin/bash
# Agent install
wget -qO - https://packages.fluentbit.io/fluentbit.key | sudo apt-key add -
sudo sh -c 'echo "deb https://packages.fluentbit.io/ubuntu/focal focal main" >>  /etc/apt/sources.list'
sudo apt-get update
sudo apt-get install -y td-agent-bit
sudo service td-agent-bit start
