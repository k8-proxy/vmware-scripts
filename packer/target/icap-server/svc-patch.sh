#!/bin/bash
  
EXTERNAL_IP=$1

kubectl -n icap-adaptation patch svc icap-svc-host -p "{\"spec\":{\"externalIPs\":[\"$EXTERNAL_IP\"]}}"
