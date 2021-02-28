#!/bin/bash

cat > /home/centos/flush_iptables.sh <<EOF
#!/bin/bash
sudo iptables --flush
sudo iptables -tnat --flush
sudo systemctl restart k3s
EOF
chmod +x /home/centos/flush_iptables.sh
# /home/centos/flush_iptables.sh

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
WantedBy=k3s.service
EOF
sudo systemctl daemon-reload
sudo systemctl enable flush_iptables.service
