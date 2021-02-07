#!/bin/bash
ICAP_SERVER=$1
RESULT_FILE=$2
COUNTER=$3
until [  $COUNTER -lt 1 ]; do
  echo "rebuild "$COUNTER
  bash rebuild.sh $ICAP_SERVER $RESULT_FILE &
  let COUNTER-=1
done