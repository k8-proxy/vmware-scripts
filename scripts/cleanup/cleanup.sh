#!/bin/bash
DEBIAN_FRONTEND=noninteractive
# Apt clean up
sudo rm -f /var/lib/apt/lists/*
sudo apt clean all
sudo rm -f /etc/ssh/*_key
sudo rm -f /etc/ssh/*.pub
sudo rm -f /home/*/.ssh/*
# Logs clean up
sudo logrotate --force /etc/logrotate.conf
sudo journalctl --rotate && sudo journalctl --vacuum-size=1
# Network clean up
sudo rm /etc/netplan/*.yml /etc/netplan/*.yaml
sudo tee /etc/netplan/network.yaml >/dev/null <<EOF
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
EOF
# Shell history clean up
history -c && history -w
