#!/bin/sh

pkill 'dhcpcd'
ifconfig wlan0 0.0.0.0
