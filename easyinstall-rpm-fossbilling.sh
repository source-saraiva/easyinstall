#!/bin/bash

# === Style Functions ===
echoyellow() { echo -e "\e[33m$1\e[0m"; }
echored()    { echo -e "\e[31m$1\e[0m"; }
echogreen()  { echo -e "\e[32m$1\e[0m"; }
echoblue()   { echo -e "\e[94m$1\e[0m"; }
echocyan()   { echo -e "\e[36m$1\e[0m"; }

# === MOTD ===
echoyellow "=== Easy Install Script (FOSSBilling) ==="
echoyellow "This script will install and configure a FOSSBilling Server on RPM-based systems."
echogreen ""
echogreen ""

# === REPOSITORIES ===
sudo dnf install -y epel-release
sudo dnf update -y


# === FIREWALL ===
echoyellow  "Openning ports on firewall"
sudo firewall-cmd --add-service={http,https} --permanent
sudo firewall-cmd --reload


# === MYSQL / MARIADB ===
echoyellow  "Installing and securing MariaDB..."
MYSQL_ROOT_PASS=$(openssl rand -base64 16)
SOLUTIONS_DB_PASS=$(openssl rand -base64 16)

sudo dnf install -y mariadb-server
sudo systemctl enable --now mariadb

mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASS}';"
mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "DELETE FROM mysql.user WHERE User='';"
mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "DROP DATABASE IF EXISTS test;"
mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "FLUSH PRIVILEGES;"

mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "CREATE DATABASE guacamole_db;"
mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "CREATE OR REPLACE USER 'guacamole_user'@'localhost' IDENTIFIED BY '${SOLUTIONS_DB_PASS}';"
mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON guacamole_db.* TO 'guacamole_user'@'localhost';"
mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "FLUSH PRIVILEGES;"

# === NGNIX ===
echoyellow  "Installing Ngnix..."
sudo dnf install -y nginx
sudo systemctl enable --now nginx

# === PHP ===
echoyellow  "Installing and configuring php ..."
sudo dnf module reset php
sudo dnf module enable -y php:8.3
sudo dnf install -y php php-fpm php-mysqlnd php-curl php-cli php-zip php-common php-mbstring php-xml

PHP_INI="/etc/php.ini"

# Backup the original php.ini
cp $PHP_INI ${PHP_INI}.bak

# Apply new configuration values
sed -i 's/^upload_max_filesize\s*=.*/upload_max_filesize = 16M/' "$PHP_INI"
sed -i 's/^post_max_size\s*=.*/post_max_size = 32M/' "$PHP_INI"
sed -i 's/^memory_limit\s*=.*/memory_limit = 256M/' "$PHP_INI"
sed -i 's/^max_execution_time\s*=.*/max_execution_time = 600/' "$PHP_INI"
sed -i 's/^max_input_vars\s*=.*/max_input_vars = 3000/' "$PHP_INI"
sed -i 's/^max_input_time\s*=.*/max_input_time = 1000/' "$PHP_INI"

echoyellow "PHP settings updated in $PHP_INI"


# === DEPENDENCIES ===
echoyellow  "Installing dependecies..."
sudo dnf install -y dnf-utils wget curl tar unzip nano vim dnf-plugins-core



# === USEFUL INFORMATION ===
echogreen ""
echogreen "FOSSBilling Server installed successfully!"
echogreen "--------------------------------------"
echogreen "Save this information"
echogreen "Mysql credentials:"
echogreen "    user: root pass: ${MYSQL_ROOT_PASS}"
echogreen "To check service status:"
echogreen "    systemctl status mariadb"
echogreen "To view logs:"
echogreen "    journalctl -u mariadb"
echogreen ""
echogreen "--------------------------------------"
echogreen "More scripts @ https://github.com/source-saraiva/easyinstall/"
echogreen "--------------------------------------"