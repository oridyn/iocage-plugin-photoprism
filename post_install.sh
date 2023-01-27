#!/bin/sh

# Configure startup parameters:
sysrc mysql_enable="YES"
sysrc mysql_args="--bind-address=127.0.0.1"

# Start mysql:
service mysql-server start

# Harden the MariaDB installation:
# Since mysql_secure_installation is interactive, we'll do the tasks performed by it manually
mysql --user=root <<_EOF_
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
_EOF_

# Generate some passwords
export LC_ALL=C
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1 > /root/db_password
DB_PASSWORD=`cat /root/db_password`
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1 > /root/admin_password
ADMIN_PASSWORD=`cat /root/admin_password`



# Configure the DB
# Create user and database for Piwigo with unique password
DB_USER="photoprism"
DB="photoprism"
# Save the config values
echo "$DB" > /root/db_name
echo "$DB_USER" > /root/db_user
echo "Database User: $DB_USER"
echo "Database Password: $DBPASSWORD"
mysql --user=root <<_EOF_
CREATE DATABASE ${DB}
CHARACTER SET = 'utf8mb4'
COLLATE = 'utf8mb4_unicode_ci';
CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB}.* to '${DB_USER}'@'%';
FLUSH PRIVILEGES;
_EOF_

# Configure PhotoPrism​
# pkg add https://github.com/psa/libtensorflow1-freebsd-port/releases/download/1.15.5/libtensorflow1-1.15.5-FreeBSD-12.2-noAVX.pkg
pkg add https://github.com/psa/libtensorflow1-freebsd-port/releases/download/1.15.5-pre-release-0/libtensorflow1-1.15.5-FreeBSD-12.3-AVX.pkg
pkg add https://github.com/psa/photoprism-freebsd-port/releases/download/2022-11-18/photoprism-g20221118-FreeBSD-12.3-separatedTensorflow.pkg

sysrc photoprism_enable="YES"
sysrc photoprism_assetspath="/var/db/photoprism/assets"
sysrc photoprism_storagepath="/mnt/photos/"
sysrc photoprism_defaultsyaml="/mnt/photos/options.yml"

mkdir /mnt/photos
chown -R photoprism:photoprism /mnt/photos
cat >/mnt/photos/options.yml <<EOL
AdminPassword: ${ADMIN_PASSWORD}
AssetsPath: /var/db/photoprism/assets
StoragePath: /mnt/photos
OriginalsPath: /mnt/photos/originals
ImportPath: /mnt/photos/import
DatabaseDriver: mysql
DatabaseName: ${DB}
DatabaseServer: "127.0.0.1:3306"
DatabaseUser: ${DB_USER}
DatabasePassword: ${DB_PASSWORD}
EOL

# Set up mDNS
sysrc nginx_enable="YES"
sysrc dbus_enable="YES"
sysrc avahi_daemon_enable="YES"
rm /usr/local/etc/avahi/services/*.service
cat >/usr/local/etc/avahi/services/http.service <<EOL
<?xml version="1.0" standalone='no'?><!--*-nxml-*-->
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name replace-wildcards="yes">%h</name>
  <service>
    <type>_http._tcp</type>
    <port>80</port>
  </service>
</service-group>
EOL

service photoprism start
service dbus start
service avahi-daemon start
service nginx start

# Add plugin detals to info file available in TrueNAS Plugin Additional Info
HOSTNAME=`hostname`;
echo "URL: http://$HOSTNAME.local" > /root/PLUGIN_INFO
echo "Admin Password: $ADMIN_PASSWORD" >> /root/PLUGIN_INFO
echo "Database User: $DB_USER" >> /root/PLUGIN_INFO
echo "Database Password: $DB_PASSWORD" >> /root/PLUGIN_INFO
echo "Database Name: $DB" >> /root/PLUGIN_INFO