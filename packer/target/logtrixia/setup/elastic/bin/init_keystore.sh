#!/bin/sh
set -eux

PASSWORD=$1
elasticsearch-keystore create
echo "$PASSWORD" | elasticsearch-keystore add -x "boostrap.password"
cp /usr/share/elasticsearch/config/elasticsearch.keystore /usr/share/elasticsearch/tmp/.