#!/bin/bash
set -e

# --- User setup (runtime, depends on PVC-backed /home) ---
if ! id basraven &> /dev/null; then
  if id -un 1000 &> /dev/null 2>&1; then
    usermod -l basraven -d /home/basraven "$(id -un 1000)"
  else
    if [ -d /home/basraven ]; then
      useradd -u 1000 -d /home/basraven -M -s /bin/bash basraven
    else
      useradd -u 1000 -d /home/basraven -m -s /bin/bash basraven
    fi
  fi
fi
echo "basraven ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/basraven

# --- Desktop startup ---
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
