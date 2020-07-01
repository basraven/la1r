#!/bin/bash
echo "The following systems need a restart":
cat /var/run/reboot-required.pkgs

read -p "Are you sure you want to restart dbus etc.? " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

echo "Enabling Manual restart on dbus service..."
sed -i 's/RefuseManualStart=yes/RefuseManualStart=no/g' /lib/systemd/system/dbus.service
systemctl daemon-reload # load new config

# 1. bring down DM, it would crash anyway
# systemctl stop display-manager #SEB: not loaded on server

# 2. restard dbus
echo "restarting dbus..."
systemctl restart dbus

# 3. restart systemd
echo "daemon-reexec...."
systemctl daemon-reexec

# 4. restart daemons that directly depend on dbus
echo "restart systemd-logind systemd-journald..."
systemctl restart systemd-logind systemd-journald # NetworkManager

# 5. start DM
#systemctl start display-manager

# Remove dbus from reboot required file
echo "removing dbus from /var/run/reboot-required.pkgs..."
sed -i 's/dbus//g'  /var/run/reboot-required.pkgs

# Remove reboot-required file if empty
echo "remove reboot-required file if empty..."
reboot_file=/var/run/reboot-required.pkgs
if ! grep -q '[^[:space:]]' "$reboot_file"; then
    echo "reboot-required file is empty, removing it..."
    rm -f $reboot_file
else
    echo "reboot-required file was not empty, sorry"
fi

