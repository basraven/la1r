#!/bin/sh
set -eu
echo "Tuning the container..."
echo "alias occ='su -l www-data -s /var/www/html/occ'" >> ~/.bashrc
a2enmod http2
a2enmod ssl
echo "Protocols h2 h2c http/1.1" >> /etc/apache2/apache2.conf
/entrypoint.sh apache2-foreground