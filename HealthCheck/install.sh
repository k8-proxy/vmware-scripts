#!/bin/bash
get () {
	curl -s $1 -o $2 || wget -q -O $2 $1
}
get https://raw.githubusercontent.com/MariuszFerdyn/vmware-scripts/main/HealthCheck/pyCheck.py pyCheck.py
chmod +x pyCheck.py
get https://raw.githubusercontent.com/MariuszFerdyn/vmware-scripts/main/HealthCheck/config.yml config.yml
