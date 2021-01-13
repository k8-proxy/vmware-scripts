# Health Check script

This script can be used to check Health of automaticly created solutions in pipelines e.g. OVA Creation. This can be also used as a standalone solution.

### New Features 2021-01-12
* fixed Round Trip Time
* Output to console - set in config.yml
* Output to file - set in config.yml
* Output to syslog - set in config.yml

### Features 
* ping check
* TCP port check
* http/https code status check (eg. 200)
* http/https return string check
* ICAP check if returned file is modified

### Install
```bash
sudo su -
cd /opt
mkdir healthcheck
cd healthcheck/
sh <(curl -s https://raw.githubusercontent.com/MariuszFerdyn/vmware-scripts/main/HealthCheck/install.sh || wget -q -O - https://raw.githubusercontent.com/MariuszFerdyn/vmware-scripts/main/HealthCheck/install.sh)
```
### Usage

Edit config.yml with checks and run using (ICAP is not working):
```bash
./pyCheck.py
```
If you want to display how many checks fails or use it in pipelines use:
```bash
echo $?
```
### This will add Health Check script to the cron and it will run every minute and put data to syslog:
```bash
echo '* * * * * root /opt/healthcheck/pyCheck.py' > /etc/cron.d/pyMonitor
```
### Filter healcheck output from syslog
```
grep 'healthcheck' /var/log/syslog
```
