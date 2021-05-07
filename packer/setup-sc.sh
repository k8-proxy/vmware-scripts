
# defining vars
DEBIAN_FRONTEND=noninteractive
KERNEL_BOOT_LINE='net.ifnames=0 biosdevname=0'

# cloning vmware scripts repo
git clone --single-branch -b cs-api-ck8 https://github.com/k8-proxy/vmware-scripts.git ~/scripts

# install needed packages
apt install -y telnet tcpdump open-vm-tools net-tools dialog curl git sed grep fail2ban
systemctl enable fail2ban.service
tee -a /etc/fail2ban/jail.d/sshd.conf << EOF > /dev/null
[sshd]
enabled = true
port = ssh
action = iptables-multiport
logpath = /var/log/auth.log
bantime  = 10h
findtime = 10m
maxretry = 5
EOF
systemctl restart fail2ban

# switching to predictable network interfaces naming
grep "$KERNEL_BOOT_LINE" /etc/default/grub >/dev/null || sed -Ei "s/GRUB_CMDLINE_LINUX=\"(.*)\"/GRUB_CMDLINE_LINUX=\"\1 $KERNEL_BOOT_LINE\"/g" /etc/default/grub

# remove swap 
swapoff -a && rm -f /swap.img && sed -i '/swap.img/d' /etc/fstab && echo Swap removed

# update grub
update-grub

# installing the wizard
install -T ~/scripts/scripts/wizard/cwizard.sh /usr/local/bin/wizard -m 0755

# installing initconfig ( for running wizard on reboot )
cp -f ~/scripts/scripts/bootscript/initconfig.service /etc/systemd/system/initconfigwizard.service
install -T ~/scripts/scripts/bootscript/initconfig.sh /usr/local/bin/initconfig.sh -m 0755
systemctl daemon-reload

# enable initconfig for the next reboot
systemctl enable initconfigwizard

# remove vmware scripts directory
rm -rf ~/scripts/
