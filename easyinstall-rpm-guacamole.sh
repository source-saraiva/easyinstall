#!/bin/bash

# === Style Functions ===
echoyellow() { echo -e "\e[33m$1\e[0m"; }
echored()    { echo -e "\e[31m$1\e[0m"; }
echogreen()  { echo -e "\e[32m$1\e[0m"; }
echoblue()   { echo -e "\e[94m$1\e[0m"; }
echocyan()   { echo -e "\e[36m$1\e[0m"; }

# === MOTD ===
echoyellow "=== Easy Install Script (APACHE GUACAMOLE) ==="
echoyellow "This script will install and configure an apache guacamole gateway server on RPM-based systems."
echogreen ""
echogreen ""

# === REPOSITORIES ===
sudo dnf config-manager --set-enabled crb
sudo dnf install -y epel-release
sudo dnf update -y


# === UTILITIES ===
sudo dnf install -y wget curl tar unzip nano vim dnf-plugins-core


# === FIREWALL ===
sudo firewall-cmd --add-service={http,https} --permanent
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload


# === DEPENDENCIES ===
sudo dnf install -y gcc make cairo-devel libjpeg-turbo-devel \
libpng-devel libtool-ltdl-devel libuuid-devel openssl-devel \
pango-devel libssh2-devel libvncserver-devel libwebsockets-devel \
freerdp-devel libvorbis-devel libwebp-devel pulseaudio-libs-devel \
uuid-devel ffmpeg-devel


# === JAVA & TOMCAT ===
sudo dnf install -y java-11-openjdk-devel tomcat 

sudo sed -i 's|^JAVA_OPTS=.*|#&\nJAVA_OPTS="-Djava.awt.headless=true -Xmx512m -XX:MaxPermSize=256m"|' /etc/tomcat/tomcat.conf
sudo systemctl enable --now tomcat


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

mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "CREATE DATABASE guacamole_db;"
mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "CREATE OR REPLACE USER 'guacamole_user'@'localhost' IDENTIFIED BY '${SOLUTIONS_DB_PASS}';"
mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON guacamole_db.* TO 'guacamole_user'@'localhost';"
mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "FLUSH PRIVILEGES;"


# === GUACAMOLE INSTALLATION ===
cd /tmp
if [ ! -f "guacamole-server-1.5.5.tar.gz" ]; then
wget https://dlcdn.apache.org/guacamole/1.5.5/source/guacamole-server-1.5.5.tar.gz
else
  echogreen "guacamole-server-1.5.5.tar.gz already exists. Skipping download."
fi

tar -xf guacamole-server-1.5.5.tar.gz
cd guacamole-server-1.5.5/
./configure --with-systemd-dir=/etc/systemd/system/
make
sudo make install
sudo ldconfig
sudo systemctl enable --now guacd

cd /tmp
if [ ! -f "guacamole-1.5.5.war" ]; then
wget https://dlcdn.apache.org/guacamole/1.5.5/binary/guacamole-1.5.5.war
else
  echogreen "guacamole-1.5.5.war already exists. Skipping download."
fi

sudo mkdir -p /etc/guacamole/{extensions,lib}
sudo cp guacamole-1.5.5.war /var/lib/tomcat/webapps/guacamole.war
sudo ln -s /etc/guacamole /usr/share/tomcat/.guacamole
echo "GUACAMOLE_HOME=/etc/guacamole" | sudo tee -a /etc/default/tomcat

# === DATABASE AUTH MODULE ===
cd /tmp
if [ ! -f "guacamole-auth-jdbc-1.5.5.tar.gz" ]; then
wget https://dlcdn.apache.org/guacamole/1.5.5/binary/guacamole-auth-jdbc-1.5.5.tar.gz
else
  echogreen "guacamole-auth-jdbc-1.5.5.tar.gz already exists. Skipping download."
fi

tar -xf guacamole-auth-jdbc-1.5.5.tar.gz
sudo cp guacamole-auth-jdbc-1.5.5/mysql/guacamole-auth-jdbc-mysql-1.5.5.jar /etc/guacamole/extensions/

if [ ! -f "mysql-connector-j-8.0.32.tar.gz" ]; then
wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-j-8.0.32.tar.gz
else
  echogreen "mysql-connector-j-8.0.32.tar.gz already exists. Skipping download."
fi
tar -xf mysql-connector-j-8.0.32.tar.gz
sudo cp mysql-connector-j-8.0.32/mysql-connector-j-8.0.32.jar /etc/guacamole/lib/


# === SCHEMA CREATION ===
cd guacamole-auth-jdbc-1.5.5/mysql/schema
mysql -u guacamole_user -p"${SOLUTIONS_DB_PASS}" guacamole_db < 001-create-schema.sql
mysql -u guacamole_user -p"${SOLUTIONS_DB_PASS}" guacamole_db < 002-create-admin-user.sql


# === GUACAMOLE CONFIGURATION ===
cat <<EOF | sudo tee /etc/guacamole/guacamole.properties
# Guacamole proxy configuration
guacd-hostname: localhost
guacd-port: 4822

# MySQL properties
mysql-hostname: localhost
mysql-port: 3306
mysql-database: guacamole_db
mysql-username: guacamole_user
mysql-password: ${SOLUTIONS_DB_PASS}
EOF

sudo systemctl restart tomcat

# === DISPLAY FINAL URL ===
SERVER_IP=$(hostname -I | awk '{print $1}')

# === NGINX ===
sudo dnf install nginx -y
echoyellow "Please enter the URL you will use to access Guacamole (leave blank to use $(hostname -f)):"
read -r ACCESS_URL
[ -z "$ACCESS_URL" ] && ACCESS_URL=$(hostname -f)

cat <<EOF | sudo tee /etc/nginx/conf.d/guacamole.conf
server {
    listen 80;
    server_name \${SERVER_IP} \${ACCESS_URL};

    access_log /var/log/nginx/guacamole_access.log;
    error_log /var/log/nginx/guacamole_error.log;

    location / {
        proxy_pass http://localhost:8080/guacamole/;
        proxy_buffering off;
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        client_max_body_size 0;
    }
}
EOF

sudo setsebool -P httpd_can_network_connect 1
sudo nginx -t
sudo systemctl enable --now nginx


# === FAIL2BAN ===

# Instalar Fail2Ban
sudo dnf install fail2ban -y

# Habilitar e iniciar o serviço
sudo systemctl enable --now fail2ban

# Criar o filtro do Guacamole
cat <<'EOF' | sudo tee /etc/fail2ban/filter.d/guacamole-journal.conf
[Definition]
failregex = Authentication attempt from \[<HOST>.*\] for user .* failed
ignoreregex =
EOF

# Criar a jail do Guacamole
cat <<EOF | sudo tee /etc/fail2ban/jail.d/guacamole-journal.conf
[guacamole-journal]
enabled = true
filter = guacamole-journal
backend = systemd
journalmatch = _SYSTEMD_UNIT=tomcat.service
maxretry = 5
bantime = 3600
findtime = 3600
EOF

# Reiniciar o serviço para aplicar as alterações
sudo systemctl restart fail2ban



# === DISPLAY INFORMATION ===
echogreen ""
echogreen "Guacamole Server installed successfully!"
echogreen "--------------------------------------"
echogreen "Save this information"
echogreen "Guacamole is available at:"
echogreen "    tomcat http://${SERVER_IP}:8080/guacamole"
echogreen "    ngnix  http://${SERVER_IP} or  http://${ACCESS_URL}"
echogreen "    user: guacadmin pass: guacadmin"
echogreen "Mysql credentials:"
echogreen "    u: guacamole_user p: ${SOLUTIONS_DB_PASS} database: guacamole_db"
echogreen "    user: root pass: ${MYSQL_ROOT_PASS}"
echogreen "To check service status:"
echogreen "    systemctl status nginx"
echogreen "    systemctl status guacd"
echogreen "    systemctl status tomcat"
echogreen "    systemctl status mariadb"
echogreen "To view logs:"
echogreen "    journalctl -u guacd"
echogreen "    journalctl -u guacd -f"
echogreen "Configuration files:"
echogreen "    /etc/guacamole/guacamole.properties"
echocyan  "In production block acess to port 8080 "
echocyan  "sudo firewall-cmd --permanent --remove-port=8080/tcp"
echocyan  "sudo firewall-cmd --reload"
echogreen "View banned IPs"
echogreen "	sudo fail2ban-client status guacamole-journal"
echogreen ""
echogreen "--------------------------------------"
echogreen "More scripts @ https://github.com/source-saraiva/easyinstall/"
echogreen "--------------------------------------"
