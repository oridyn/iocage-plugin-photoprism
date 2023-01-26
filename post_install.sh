#!/bin/sh

# Configure startup parameters:
sysrc mysql_enable="YES"
sysrc mysql_args="--bind-address=127.0.0.1"

# Start mysql:
service mysql-server start

# Harden the MariaDB installation:
mysql_secure_installation
