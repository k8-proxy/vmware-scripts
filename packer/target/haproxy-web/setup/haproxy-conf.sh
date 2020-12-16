#!/bin/bash

# Creates a tmp file
cat > haproxy.cfg.template <<EOF
global
        log /dev/log    local0
        log /dev/log    local1 notice
        chroot /var/lib/haproxy
        stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
        stats timeout 30s
        user haproxy
        group haproxy
        daemon

        # Default SSL material locations
        ca-base /etc/ssl/certs
        crt-base /etc/ssl/private

        # See: https://ssl-config.mozilla.org/#server=haproxy&server-version=2.0.3&config=intermediate
        ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
        ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
        ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

defaults
        log     global
        mode    http
        option  httplog
        option  dontlognull
        timeout connect 5000
        timeout client  50000
        timeout server  50000
        errorfile 400 /etc/haproxy/errors/400.http
        errorfile 403 /etc/haproxy/errors/403.http
        errorfile 408 /etc/haproxy/errors/408.http
        errorfile 500 /etc/haproxy/errors/500.http
        errorfile 502 /etc/haproxy/errors/502.http
        errorfile 503 /etc/haproxy/errors/503.http
        errorfile 504 /etc/haproxy/errors/504.http
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
#backend1

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
#backend2

#Haproxy monitoring Webui(optional) configuration, access it <Haproxy IP>:32700
listen stats
bind :32700
stats enable
stats uri /
stats hide-version
stats auth username:password
EOF

cp -f haproxy.cfg.template haproxy.cfg.tmp

# Ask for input on backend servers
read -p "Please enter backend server(s) IPs, please note to space separate : " backendservers
declare -a IPS=( $backendservers )
len=${#IPS[@]}
for ((i=0; i<len; i++));
do 
    ((x=$i+1))
    sed -i "/^#backend1/ a server web$x ${IPS[i]}:80 check" haproxy.cfg.tmp
done
for ((i=0; i<len; i++));
do 
    ((x=$i+1))
    sed -i "/^#backend2/ a server web$x ${IPS[i]}:443 check" haproxy.cfg.tmp
done
mv haproxy.cfg.tmp /etc/haproxy/haproxy.cfg
rm haproxy.cfg.template
systemctl restart haproxy