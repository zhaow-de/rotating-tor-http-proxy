#!/bin/bash

BOM=$(echo "alpine-$(cat /etc/alpine-release)" && apk list --installed 2>&1 |grep -e '^bash\|^curl\|^haproxy\|^privoxy\|^sed\|^tor' |awk '{print $1}' |sed -r 's/\-r[0-9]+$//' |sort)

# the last `xargs` step is to remove the trailing whitespace (see https://stackoverflow.com/a/12973694)
echo "${BOM}" |tr '\n' ' ' |xargs
