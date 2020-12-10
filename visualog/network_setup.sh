#!/bin/sh

IP_ADDRESS=$1
NETMASK=$2
GATEWAY=$3
DNS_SERVER=$4

cp 00-installer-config.yaml.template 00-installer-config.yaml
sed -i "s/IP_ADDRESS/${IP_ADDRESS}/g" 00-installer-config.yaml 
sed -i "s/NETMASK/${NETMASK}/g" 00-installer-config.yaml 
sed -i "s/GATEWAY/${GATEWAY}/g" 00-installer-config.yaml 
sed -i "s/DNS_SERVER/${DNS_SERVER}/g" 00-installer-config.yaml 

sudo cp 00-installer-config.yaml /etc/netplan/00-installer-config.yaml

sudo netplan apply
