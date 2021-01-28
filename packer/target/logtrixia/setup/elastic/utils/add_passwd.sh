#!/bin/sh
set -eux

PASSWORD=$1
echo "$PASSWORD" | elasticsearch-keystore add -x "boostrap.password"