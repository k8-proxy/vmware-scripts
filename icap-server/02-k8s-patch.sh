#!/bin/bash
  
EXTERNAL_IP=`ip addr show ens160 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1 | head -n 1`

kubectl -n icap-adaptation patch svc icap-svc-host -p "{\"spec\":{\"externalIPs\":[\"$EXTERNAL_IP\"]}}"
