#!/bin/bash

sudo iptables --flush
sudo iptables -tnat --flush

sudo tee -a /etc/init.d/flush_iptables <<EOF
#!/bin/bash
### BEGIN INIT INFO
# Provides:             flush_iptables
# Required-Start:       $local_fs $remote_fs $network $syslog $named
# Required-Stop:        $local_fs $remote_fs $network $syslog $named
# Default-Start:        2 3 4 5
# Default-Stop:         
# Short-Description:    flush iptables
# Description:          flush iptables
### END INIT INFO
sudo iptables --flush
sudo iptables -tnat --flush
EOF
sudo chmod +x /etc/init.d/flush_iptables
sudo update-rc.d flush_iptables defaults
