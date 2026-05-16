#!/bin/bash
set -e

# 1. Start X Virtual Framebuffer
echo "Starting Xvfb on display :1..."
Xvfb :1 -screen 0 ${RESOLUTION} &
sleep 1

# 2. Start XFCE4 inside a D-Bus session (FIXES THE ERROR)
echo "Starting XFCE Desktop with D-Bus..."
dbus-run-session startxfce4 &
sleep 1

# 3. Start VNC server
echo "Starting x11vnc server on port 5900..."
x11vnc -forever -shared -display :1 -rfbport 5900 -nopw &
sleep 1

# 4. Start noVNC web proxy
echo "Starting noVNC web proxy on port 6080..."
websockify --web /usr/share/novnc 6080 localhost:5900