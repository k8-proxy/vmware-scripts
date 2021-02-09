#!/bin/bash
# Agent install
set -eux
export ELASTICSEARCH_HOST=$1
export ELASTICSEARCH_PORT=$2
export ELASTICSEARCH_USERNAME=$3
export ELASTICSEARCH_PASSWORD=$4
sudo apt-get update
wget -qO - https://packages.fluentbit.io/fluentbit.key | sudo apt-key add -
echo 'deb https://packages.fluentbit.io/ubuntu/focal focal main' | sudo tee -a /etc/apt/sources.list
sudo apt-get update
sudo apt-get install -y gettext-base td-agent-bit
envsubst < haproxy.conf.tmpl > haproxy.conf
sudo cp haproxy.conf /etc/td-agent-bit/haproxy.conf
sudo cp haproxy_parsers.conf /etc/td-agent-bit/haproxy_parsers.conf
sudo cp td-agent-bit.conf /etc/td-agent-bit/td-agent-bit.conf
sudo systemctl daemon-reload
sudo systemctl enable td-agent-bit 
sudo systemctl start td-agent-bit
