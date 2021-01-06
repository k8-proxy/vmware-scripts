#!/bin/bash
# Network setup
DEBIAN_FRONTEND=noninteractive
rm -f /etc/netplan/*.yml /etc/netplan/*.yaml
cat > /etc/netplan/network.yaml <<EOF
network:
  version: 2
  ethernets:
    ens33:
      dhcp4: false
      addresses:
      - 51.89.210.150/28 # Replace with IP Address / Netmask bits (CIDR format), ex: 192.168.1.2/24
      gateway4: 51.89.210.158 # Replace with Gateway
      nameservers:
        addresses:
        - 8.8.4.4 # Replace with DNS resolver
EOF
netplan apply
