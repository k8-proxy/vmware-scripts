#!/bin/bash
  
IP_ADDRESS_WITH_MASK=$1
GATEWAY=$2

if [[ ! $IP_ADDRESS_WITH_MASK ]]
then
   echo "Please enter an ip address"
   exit -1
fi

if [[ ! $GATEWAY ]]
then
   echo "Please enter the gateway"
   exit -1
fi

# Configuring network interfaces
python3 ./netplan.py -i $IP_ADDRESS_WITH_MASK -g $GATEWAY
