#!/bin/bash

# === Style Functions ===
echoyellow() { echo -e "\e[33m$1\e[0m"; }
echored()    { echo -e "\e[31m$1\e[0m"; }
echogreen()  { echo -e "\e[32m$1\e[0m"; }
echoblue()   { echo -e "\e[94m$1\e[0m"; }
echocyan()   { echo -e "\e[36m$1\e[0m"; }

# === MOTD ===
echoyellow "=== Easy Install Script (MARIADB) ==="
echoyellow "This script will install and configure a mariadb on RPM-based systems."
echogreen ""
echogreen ""

# === REPOSITORIES ===
sudo dnf install -y epel-release
sudo dnf update -y





# === MYSQL / MARIADB ===
echo -e "\e[1;33m>>> Installing and securing MariaDB...\e[0m"
MYSQL_ROOT_PASS=$(openssl rand -base64 16)
SOLUTIONS_DB_PASS=$(openssl rand -base64 16)

sudo dnf install -y mariadb-server
sudo systemctl enable --now mariadb

mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASS}';"
mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "DELETE FROM mysql.user WHERE User='';"
mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "DROP DATABASE IF EXISTS test;"
mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "FLUSH PRIVILEGES;"



# === USEFUL INFORMATION ===
echogreen ""
echogreen "Mariadb Server installed successfully!"
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