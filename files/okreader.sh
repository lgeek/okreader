#!/bin/bash

echo 0 > /sys/class/leds/pmic_ledsg/brightness

export WIFI_MODULE=brcmfmac

cd /opt/koreader
while true; do
 ./luajit ./reader.lua /mnt
done
