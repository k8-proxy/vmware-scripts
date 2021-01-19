#!/bin/bash
sudo apt-get install -y haproxy
sudo tee -a /etc/haproxy/haproxy.cfg << EOF > /dev/null
#The frontend is the node by which HAProxy listens for connections (http).
frontend http-glasswall
        bind *:80
        option tcplog
        mode tcp
        default_backend http-nodes  
#Backend nodes are those by which HAProxy can forward requests
backend http-nodes
        mode tcp
        balance roundrobin
        server web01 54.78.209.23:80 check

#The frontend is the node by which HAProxy listens for connections (https).
frontend https-glasswall
        bind *:443
        option tcplog
        mode tcp
        default_backend https-nodes 
#Backend nodes are those by which HAProxy can forward requests
backend https-nodes
        mode tcp
        balance roundrobin
        option ssl-hello-chk
        server web01 54.78.209.23:443 check

#Haproxy monitoring Webui(optional) configuration, access it <Haproxy IP>:32700
listen stats
bind :32700
stats enable
stats uri /
stats hide-version
stats auth username:password
EOF
sudo systemctl restart haproxy.service
mv /tmp/setup/haproxy-conf.sh ~
# This is a placeholder script, you can move your setup script here to install some custom deployment on the VM
# The parent directory of this script will be transferred with its content to the VM under /tmp/setup path
# (i.e: useful for copying configs, scripts, systemd units, etc..)  
