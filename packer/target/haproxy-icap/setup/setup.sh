#!/bin/bash
sudo mv /tmp/setup/10-elasticsearch.conf.tmpl /tmp/setup/haproxy.sh ~
sudo ufw allow 22
sudo ufw allow 1344
sudo ufw allow 1345
sudo ufw enable
sudo apt-get install -y haproxy rsyslog rsyslog-mmjsonparse rsyslog-elasticsearch rsyslog-mmutf8fix
sudo envsubst < 10-elasticsearch.conf.tmpl > /etc/rsyslog.d/elasticsearch.conf 
sudo systemcl restart rsyslog
sudo tee -a /etc/haproxy/haproxy.cfg << EOF > /dev/null
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
sudo systemctl restart haproxy.service
mv /tmp/setup/haproxy-conf.sh ~
# This is a placeholder script, you can move your setup script here to install some custom deployment on the VM
# The parent directory of this script will be transferred with its content to the VM under /tmp/setup path
# (i.e: useful for copying configs, scripts, systemd units, etc..)  
