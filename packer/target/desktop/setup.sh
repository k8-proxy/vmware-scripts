#!/bin/bash
DEBIAN_FRONTEND=noninteractive
sleep 3
sudo apt install -y ubuntu-desktop
sudo systemctl set-default graphical.target
sudo sed -i '/network/ a \ \ renderer: NetworkManager' /etc/netplan/*.yaml
sudo sed -i 's/managed=false/managed=true/g' /etc/NetworkManager/NetworkManager.conf
sudo netplan apply
