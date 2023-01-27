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





# Add plugin detals to info file available in TrueNAS Plugin Additional Info
echo "Host: 127.0.0.1" > /root/PLUGIN_INFO
echo "Database User: $USER" >> /root/PLUGIN_INFO
echo "Database Password: $PASS" >> /root/PLUGIN_INFO
echo "Database Name: $DB" >> /root/PLUGIN_INFO