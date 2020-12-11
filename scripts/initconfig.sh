#!/bin/bash

sleep 10
clear
echo "



InitConfig

"

#nowe haslo dla uzytkownika glasswall
/usr/bin/wizard.sh

systemctl disable initconfig

reboot
exit
