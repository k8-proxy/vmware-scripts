#!/bin/bash
DEBIAN_FRONTEND=noninteractive
sleep 3
sudo apt install -y ubuntu-desktop
sudo systemctl set-default graphical.target
