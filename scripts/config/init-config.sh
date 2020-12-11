#!/bin/bash
DEBIAN_FRONTEND=noninteractive
echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$USER >/dev/null
sudo apt update && sudo apt upgrade -y
sudo apt install -y telnet tcpdump open-vm-tools net-tools dialog curl git sed grep
KERNEL_BOOT_LINE='net.ifnames=0 biosdevname=0'
grep "$KERNEL_BOOT_LINE" /etc/default/grub >/dev/null || sudo sed -Ei "s/GRUB_CMDLINE_LINUX=\"(.*)\"/GRUB_CMDLINE_LINUX=\"\1 $KERNEL_BOOT_LINE\"/g" /etc/default/grub
sudo update-grub
git clone --single-branch -b main https://github.com/k8-proxy/vmware-scripts.git ~/scripts
sudo install -T ~/scripts/scripts/wizard/wizard.sh /usr/local/bin/wizard -m 0755
sudo cp -f ~/scripts/scripts/bootscript/initconfig.service /etc/systemd/system/initconfig.service
sudo install -T ~/scripts/scripts/bootscript/initconfig.sh /usr/local/bin/initconfig.sh -m 0755
sudo systemctl daemon-reload
sudo systemctl enable initconfig
