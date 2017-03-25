#!/bin/sh

# Load wifi modules and enable wifi.
lsmod | grep -q $WIFI_MODULE || modprobe $WIFI_MODULE
lsmod | grep -q sdio_wifi_pwr || modprobe sdio_wifi_pwr
sleep 1

ifconfig wlan0 up

pidof wpa_supplicant >/dev/null || \
    ( wpa_supplicant -D wext -iwlan0 -C /var/run/wpa_supplicant -B; \
      ln -s /var/run/wpa_supplicant/wlan0 /var/run/wpa_supplicant/eth0 )
