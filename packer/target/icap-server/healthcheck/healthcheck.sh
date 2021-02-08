cd /home/ubuntu/healthcheck
if [ -f "output.pdf" ]; then
        rm output.pdf
fi
timeout 30s /usr/bin/c-icap-client -i 127.0.0.1  -p 1344 -s gw_rebuild -f input.pdf -o output.pdf -v
if [ $? -eq 0 ]; then
        cat output.pdf | grep "Glasswall Processed"
        if [ $? -eq 0 ]; then
                if [ -f "status.fail" ]; then
                        rm status.fail
                fi
                touch status.ok
        else
                if [ -f "status.ok" ]; then
                        rm status.ok
                fi 
                touch status.fail
        fi
else
        if [ -f "status.ok" ]; then
                rm status.ok
        fi  
        touch status.fail
fi