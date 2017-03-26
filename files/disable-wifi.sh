#!/bin/sh

# Disable wifi, and remove all modules.

pkill dhcpcd
pkill wpa_supplicant

ifconfig wlan0 down

# Some sleep in between may avoid system getting hung
# (we test if a module is actually loaded to avoid unneeded sleeps)
if lsmod | grep -q $WIFI_MODULE ; then
    rmmod $WIFI_MODULE
fi
if lsmod | grep -q sdio_wifi_pwr ; then
    rmmod sdio_wifi_pwr
fi
