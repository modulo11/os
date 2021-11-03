#!/usr/bin/env bash

if (( UID != 0 )); then
    echo "Script need to be run as root!"
	exit
fi

echo "If you see any errors, try to unfreeze your SSD e.g. 'systemctl suspend'"

PASSWORD="3D6Xgf6d"

hdparm --user-master u --security-set-pass ${PASSWORD} /dev/sda
hdparm --user-master u --security-erase ${PASSWORD} /dev/sda
