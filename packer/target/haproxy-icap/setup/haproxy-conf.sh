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
#Logging
global
  log 127.0.0.1:514  local0 
  profiling.tasks on
defaults
  log global
  log-format "%ci:%cp [%t] %ft %b/%s %Tw/%Tc/%Tt %B %ts %ac/%fc/%bc/%sc/%rc %sq/%bq"
#The frontend is the node by which HAProxy listens for connections.
frontend ICAP
bind 0.0.0.0:1344
mode tcp
default_backend icap_pool
#Backend nodes are those by which HAProxy can forward requests
backend icap_pool
balance roundrobin
mode tcp
server icap01 54.77.168.168:1344 check
server icap02 3.139.22.215:1344 check

#The frontend is the node by which HAProxy listens for connections.
frontend S-ICAP
bind 0.0.0.0:1345
mode tcp
default_backend s-icap_pool
#Backend nodes are those by which HAProxy can forward requests
backend s-icap_pool
balance roundrobin
mode tcp
server icap01 54.77.168.168:1345 check
server icap02 3.139.22.215:1345 check

#Haproxy monitoring Webui(optional) configuration, access it <Haproxy IP>:32700
listen stats
bind :32700
option http-use-htx
http-request use-service prometheus-exporter if { path /metrics }
stats enable
stats uri /
stats hide-version
stats auth username:password
EOF

cp -f haproxy.cfg.template haproxy.cfg.tmp

# Ask for input on backend servers
read -e -p "Please enter backend server(s) IPs, please note to space separate : " backendservers
declare -a IPS=( $backendservers )
len=${#IPS[@]}
for ((i=0; i<len; i++));
do 
    ((x=$i+1))
    sed -i "/^#backend1/ a server icap$x ${IPS[i]}:1344 check" haproxy.cfg.tmp
done
for ((i=0; i<len; i++));
do 
    ((x=$i+1))
    sed -i "/^#backend2/ a server icap$x ${IPS[i]}:1345 check" haproxy.cfg.tmp
done
mv haproxy.cfg.tmp /etc/haproxy/haproxy.cfg
rm haproxy.cfg.template
systemctl restart haproxy
