#!/bin/bash
#set -eux
ICAP_SERVER=$1
RESULT_FILE=$2
COUNTER=$3
SLEEP=$4
while true
do
  until [  $COUNTER -lt 1 ]; do
    echo "rebuild "$COUNTER
    bash rebuild.sh $ICAP_SERVER $RESULT_FILE &
    let COUNTER-=1
  done
  COUNTER=$3
  echo "counter: "$COUNTER
  echo "sleep $SLEEP"
  sleep $SLEEP
done