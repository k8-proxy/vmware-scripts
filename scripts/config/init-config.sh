#!/bin/bash
DEBIAN_FRONTEND=noninteractive
echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$USER >/dev/null
sudo apt update && sudo apt upgrade 
sudo apt install -y telnet tcpdump open-vm-tools net-tools dialog curl git sed grep
KERNEL_BOOT_LINE='net.ifnames=0 biosdevname=0'
grep "$KERNEL_BOOT_LINE" /etc/default/grub >/dev/null || sudo sed -iE "s/GRUB_CMDLINE_LINUX=\"(.*)\"/GRUB_CMDLINE_LINUX=\"\1 $KERNEL_BOOT_LINE\"/g" /etc/default/grub
sudo update-grub
git clone --single-branch -b main https://github.com/k8-proxy/vmware-scripts.git ~/scripts
sudo install -T ~/scripts/scripts/wizard/wizard.sh /usr/local/bin/wizard -m 0755
install -T ~/scripts/scripts/pw-reset-onlogin/pw-reset-onlogin.sh /tmp/pw-reset-onlogin.sh -m 0755
