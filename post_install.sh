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

# Configure the DB
# Create user and database for Piwigo with unique password
USER="photoprism"
DB="photoprism"
# Save the config values
echo "$DB" > /root/dbname
echo "$USER" > /root/dbuser
export LC_ALL=C
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1 > /root/dbpassword
PASS=`cat /root/dbpassword`
echo "Database User: $USER"
echo "Database Password: $PASS"
mysql --user=root <<_EOF_
CREATE DATABASE ${DB}
CHARACTER SET = 'utf8mb4'
COLLATE = 'utf8mb4_unicode_ci';
CREATE USER '${USER}'@'%' IDENTIFIED BY '${PASS}';
GRANT ALL PRIVILEGES ON ${DB}.* to '${USER}'@'%';
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
AuthMode: public #[OPTIONAL]
AssetsPath: /var/db/photoprism/assets
StoragePath: /mnt/photos
OriginalsPath: /mnt/photos/originals
ImportPath: /mnt/photos/import
DatabaseDriver: mysql
DatabaseName: ${DB}
DatabaseServer: "127.0.0.1:3306"
DatabaseUser: ${USER}
DatabasePassword: ${PASS}
EOL

service photoprism start

# Add plugin detals to info file available in TrueNAS Plugin Additional Info
echo "Host: 127.0.0.1" > /root/PLUGIN_INFO
echo "Database User: $USER" >> /root/PLUGIN_INFO
echo "Database Password: $PASS" >> /root/PLUGIN_INFO
echo "Database Name: $DB" >> /root/PLUGIN_INFO