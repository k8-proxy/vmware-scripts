#!/bin/bash
ICAP_SERVER=$1
RESULT_FILE=$2  
UUID=$(cat /proc/sys/kernel/random/uuid)
{ time c-icap-client -i $ICAP_SERVER -p 1344 -s gw_rebuild?traceId=$UUID -f Execute+Java+Script_JS_PDF.pdf -o out/$UUID.pdf -v ; } 2> log/$UUID.log
result=$(cat log/$UUID.log | grep HTTP)
elapsed_time=$(cat log/$UUID.log | grep real | sed -E 's/[^0-9\.]+//g' | tr -d '\n' | (cat && echo ' * 1000') | bc)
echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ"),$ICAP_SERVER,$UUID,$result,$elapsed_time" >> $RESULT_FILE
rm log/$UUID.log
rm out/$UUID.pdf

