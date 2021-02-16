#!/bin/bash
DEBIAN_FRONTEND=noninteractive
# yum clean up
sudo rm -f /var/lib/apt/lists/* 2>/dev/null || true
sudo yum clean all
sudo rm -f /home/*/.ssh/*
# Logs clean up
sudo logrotate --force /etc/logrotate.conf
sudo journalctl --rotate && sudo journalctl --vacuum-size=1
# Network clean up
sudo rm -f /etc/netplan/*.yml /etc/netplan/*.yaml
# Shell history clean up
history -c && history -w
# remove HWADDR from network config file
sudo sed -i "/HWADDR=.*/d" /etc/sysconfig/network-scripts/ifcfg-eth0