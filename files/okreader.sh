#!/bin/bash

export WIFI_MODULE=brcmfmac

cd /opt/koreader
while true; do
 ./luajit ./reader.lua /mnt
done
