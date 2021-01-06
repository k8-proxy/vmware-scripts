#!/bin/bash
# Agent install
apt-get update
wget -qO - https://packages.fluentbit.io/fluentbit.key | sudo apt-key add -
echo "deb https://packages.fluentbit.io/ubuntu/focal focal main" >>  /etc/apt/sources.list
apt-get install -y td-agent-bit
service td-agent-bit start
