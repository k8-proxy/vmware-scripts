#!/bin/bash
  
IP_ADDRESS_WITH_MASK=$1
GATEWAY=$2

# Configuring network interfaces
python3 ./netplan.py -i $IP_ADDRESS_WITH_MASK -g $GATEWAY
