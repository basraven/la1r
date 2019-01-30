#!/bin/sh
set -eu
echo "[Raven] Tuning the container..."
echo "alias www-data='su -l www-data -s /bin/bash'" >> ~/.bashrc
apt-get update
apt-get install cron
echo "" >> /etc/crontab
echo "*/15  *  *  *  * www-data php -f /var/www/html/cron.php" >> /etc/crontab
echo "*/10  *  *  *  * www-data /var/www/html/occ preview:pre-generate" >> /etc/crontab

# TODO: Run this:
# /var/www/html/occ files:scan --all
# /var/www/html/occ preview:generate-all
# /var/www/html/occ twofactorauth:enforce --on


service cron start
a2enmod http2
a2enmod ssl
echo "Protocols h2 h2c http/1.1" >> /etc/apache2/apache2.conf
echo "[Raven] Done tuning the container"
/entrypoint.sh apache2-foreground