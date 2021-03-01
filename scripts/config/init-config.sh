#!/bin/bash
# defining vars
KERNEL_BOOT_LINE='net.ifnames=0 biosdevname=0'

# sudo without password prompt
echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$USER >/dev/null

# update packages
sudo yum update -y

# install needed packages
sudo yum install epel-release -y
sudo yum install -y telnet tcpdump open-vm-tools net-tools dialog curl git sed grep fail2ban wget
sudo wget https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 -O /usr/bin/yq
sudo chmod +x /usr/bin/yq
sudo systemctl enable fail2ban.service
sudo tee -a /etc/fail2ban/jail.d/sshd.conf << EOF > /dev/null
[sshd]
enabled = true
port = ssh
action = iptables-multiport
logpath = /var/log/auth.log
bantime  = 10h
findtime = 10m
maxretry = 5
EOF
sudo systemctl restart fail2ban

# cloning vmware scripts repo
git clone --single-branch -b centos7_based https://github.com/k8-proxy/vmware-scripts.git  ~/scripts

# switching to predictable network interfaces naming
grep "$KERNEL_BOOT_LINE" /etc/default/grub >/dev/null || sudo sed -Ei "s/GRUB_CMDLINE_LINUX=\"(.*)\"/GRUB_CMDLINE_LINUX=\"\1 $KERNEL_BOOT_LINE\"/g" /etc/default/grub

# allow password authentication
if [ -f /tmp/setup/env ] ; then
source /tmp/setup/env
fi
SSH_PASSWORD=${SSH_PASSWORD:-glasswall}
sudo sed -Ei "s|ssh_pwauth:(.*)|ssh_pwauth: true|g" /etc/cloud/cloud.cfg
sudo sed -Ei "s|lock_passwd:(.*)|lock_passwd: false|g" /etc/cloud/cloud.cfg
sudo yq w -i /etc/cloud/cloud.cfg system_info.default_user.plain_text_passwd $SSH_PASSWORD
sudo tee -a /etc/cloud/cloud.cfg <<EOF
preserve_hostname: true
EOF
# sudo touch /etc/cloud/cloud-init.disabled

# remove swap 
sudo swapoff -a && sudo rm -f /swap.img && sudo sed -i '/swap.img/d' /etc/fstab && echo Swap removed

# update grub
# sudo update-grub

# installing the wizard
sudo install -T ~/scripts/scripts/wizard/wizard.sh /usr/local/bin/wizard -m 0755

# installing initconfig ( for running wizard on reboot )
sudo cp -f ~/scripts/scripts/bootscript/initconfig.service /etc/systemd/system/initconfig.service
sudo install -T ~/scripts/scripts/bootscript/initconfig.sh /usr/local/bin/initconfig.sh -m 0755
sudo systemctl daemon-reload

# enable initconfig for the next reboot
sudo systemctl enable initconfig

# install node exporter
# wget https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz -qO- | tar xz -C /tmp/
# sudo install -T /tmp/node_exporter-1.0.1.linux-amd64/node_exporter /usr/local/bin/node_exporter -m 0755

# create node exporter user
# sudo useradd node_exporter -s /sbin/nologin

# create node exporter service
# sudo cp ~/scripts/visualog/monitoring-scripts/node_exporter.service /etc/systemd/system/node_exporter.service
# sudo mkdir -p /etc/prometheus

# install node exporter configuration
# sudo cp ~/scripts/visualog/monitoring-scripts/node_exporter.config /etc/prometheus/node_exporter.config
# sudo systemctl daemon-reload

# start and enable node_exporter service
# sudo systemctl enable --now node_exporter

# remove vmware scripts directory
rm -rf ~/scripts/
