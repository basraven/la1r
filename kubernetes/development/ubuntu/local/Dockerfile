FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install utilities, XFCE, VNC, noVNC, Git, and the Papirus icon theme
RUN apt-get update && apt-get install -y \
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
    papirus-icon-theme \
    && rm -rf /var/lib/apt/lists/*

# 2. Clone the official Nordic GTK theme directly from GitHub into the system themes folder
RUN git clone --depth 1 https://github.com/EliverLara/Nordic.git /usr/share/themes/Nordic

# 3. Create the default XFCE settings directory and force Nordic + Papirus-Dark as system defaults
RUN mkdir -p /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/ && \
    echo '<?xml version="1.0" encoding="UTF-8"?><channel name="xsettings" version="1.0"><property name="Net" type="empty"><property name="ThemeName" type="string" value="Nordic"/><property name="IconThemeName" type="string" value="Papirus-Dark"/></property></channel>' > /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml && \
    echo '<?xml version="1.0" encoding="UTF-8"?><channel name="xfwm4" version="1.0"><property name="general" type="empty"><property name="theme" type="string" value="Nordic"/></property></channel>' > /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml

# 4. Standard noVNC configuration link
RUN ln -s /usr/share/novnc/vnc.html /usr/share/novnc/index.html

ENV DISPLAY=:1
ENV RESOLUTION=1280x800x24

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 5900 6080

ENTRYPOINT ["/entrypoint.sh"]