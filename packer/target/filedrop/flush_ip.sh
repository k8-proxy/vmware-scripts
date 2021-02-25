#!/bin/bash

cat > /home/centos/flush_iptables.sh <<EOF
#!/bin/bash
sudo iptables --flush
sudo iptables -tnat --flush

kubectl scale --replicas=0 deployment.apps/k8-rebuild-sow-rest
kubectl scale --replicas=0 ddeployment.apps/sow-rest-api
kubectl scale --replicas=0 deployment.apps/sow-rest-ui

kubectl scale --replicas=1 deployment.apps/k8-rebuild-sow-rest
kubectl scale --replicas=1 ddeployment.apps/sow-rest-api
kubectl scale --replicas=1 deployment.apps/sow-rest-ui
EOF
chmod +x /home/centos/flush_iptables.sh
/home/centos/flush_iptables.sh

sudo tee -a /etc/systemd/system/flush_iptables.service <<EOF
 [Unit]
Description=Flush iptables
After=network.target

[Service]
Type=simple
User=centos
ExecStart=/home/centos/flush_iptables.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable flush_iptables.service
