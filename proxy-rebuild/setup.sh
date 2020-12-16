#!/bin/bash

cd ~
git clone https://github.com/k8-proxy/s-k8-proxy-rebuild.git
git clone https://github.com/k8-proxy/vmware-scripts.git

# generate self signed certificates
cd vmware-scripts/proxy-rebuild
chmod +x gencert.sh
./gencert.sh

# setup proxy
chmod +x 02-setup-proxy.sh
echo '54.77.168.168\n\n\n' | ./02-setup-proxy.sh
