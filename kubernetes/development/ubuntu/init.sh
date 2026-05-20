#!/bin/bash
set -e

# --- User setup (runtime, depends on PVC-backed /home) ---
if ! id basraven &> /dev/null; then
  if id -un 1000 &> /dev/null 2>&1; then
    if command -v usermod &> /dev/null; then
      usermod -l basraven -d /home/basraven "$(id -un 1000)"
    else
      # UID 1000 exists but usermod/useradd not available — direct edit
      sed -i "s/^$(id -un 1000):/basraven:/" /etc/passwd
      sed -i "s/^$(id -un 1000):/basraven:/" /etc/shadow 2>/dev/null || true
      sed -i "s/^$(id -un 1000):/basraven:/" /etc/group 2>/dev/null || true
    fi
  else
    if command -v useradd &> /dev/null; then
      if [ -d /home/basraven ]; then
        useradd -u 1000 -d /home/basraven -M -s /bin/bash basraven
      else
        useradd -u 1000 -d /home/basraven -m -s /bin/bash basraven
      fi
    else
      # useradd not available — direct passwd entry
      echo "basraven:x:1000:1000::/home/basraven:/bin/bash" >> /etc/passwd
      echo "basraven:!:20000:0:99999:7:::" >> /etc/shadow 2>/dev/null || true
      [ -d /home/basraven ] || mkdir -p /home/basraven
    fi
  fi
fi
echo "basraven ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/basraven

# --- Install missing development tools ---
if [ -f /install-tools.sh ]; then
  bash /install-tools.sh
fi

# --- Desktop startup ---
echo "Starting Xvfb on display :1..."
Xvfb :1 -screen 0 ${RESOLUTION} &
sleep 1

echo "Starting XFCE Desktop with D-Bus..."
dbus-run-session startxfce4 &
sleep 1

echo "Starting x11vnc server on port 5900 (password auth)..."
x11vnc -forever -shared -display :1 -rfbport 5900 -passwd "$(cat /etc/vnc-auth/password)" &
sleep 1

echo "Starting noVNC web proxy on port 6080..."
exec websockify --web /usr/share/novnc 6080 localhost:5900
