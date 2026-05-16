#!/bin/bash
set -e

echo "Installing desktop packages..."
apt-get update
apt-get install -y \
    xfce4 \
    xfce4-goodies \
    dbus-x11 \
    xvfb \
    x11vnc \
    novnc \
    websockify \
    net-tools \
    curl \
    git \
    papirus-icon-theme

echo "Copying Nordic theme..."
cp -r /setup/Nordic /usr/share/themes/

echo "Configuring XFCE defaults..."
mkdir -p /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/
cp /setup/xfce4/xfconf/xfce-perchannel-xml/*.xml /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/

echo "Setting up noVNC..."
ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html

echo "Cleaning up apt cache..."
rm -rf /var/lib/apt/lists/*

echo "Starting Xvfb on display :1..."
Xvfb :1 -screen 0 ${RESOLUTION} &
sleep 1

echo "Starting XFCE Desktop with D-Bus..."
dbus-run-session startxfce4 &
sleep 1

echo "Starting x11vnc server on port 5900..."
x11vnc -forever -shared -display :1 -rfbport 5900 -nopw &
sleep 1

echo "Starting noVNC web proxy on port 6080..."
exec websockify --web /usr/share/novnc 6080 localhost:5900
