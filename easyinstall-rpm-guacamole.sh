#!/bin/bash

# === Style Functions ===
echoyellow() { echo -e "\e[33m$1\e[0m"; }
echored()    { echo -e "\e[31m$1\e[0m"; }
echogreen()  { echo -e "\e[32m$1\e[0m"; }
echoblue()   { echo -e "\e[94m$1\e[0m"; }
echocyan()   { echo -e "\e[36m$1\e[0m"; }

# Prompt function with default
prompt_nonempty_default() {
    local prompt="$1"
    local default="$2"
    local var
    while true; do
        read -p "$prompt [$default]: " var
        var="${var:-$default}"
        if [[ -n "$var" ]]; then
            echo "$var"
            break
        else
            echored "Input cannot be empty. Please try again."
        fi
    done
}

# === Guacamole Easy Installer ===
echoyellow "=== Easy Install Script (Apache Guacamole on AlmaLinux) ==="

# Detect IP address
SERVER_IP=$(ip route get 1.1.1.1 | awk '/src/ {print $7; exit}')
SERVER_IP=$(prompt_nonempty_default "Enter your server's public IP" "$SERVER_IP")

# === FIREWALL ===
echoyellow ">>> Configuring firewall..."
sudo firewall-cmd --add-service={http,https} --permanent
sudo firewall-cmd --reload

# === REPOSITORY ===
echoyellow ">>> Enabling repositories..."
sudo dnf install -y epel-release
sudo dnf install -y https://download1.rpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E %rhel).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-$(rpm -E %rhel).noarch.rpm
sudo dnf config-manager --set-enabled crb
sudo dnf update -y
# === UTILITIES ===
echoyellow ">>> Installing utilities..."
sudo dnf install -y wget nano dnf-utils

# === DEPENDENCIES ===
echoyellow ">>> Installing dependencies..."
sudo dnf install -y cairo-devel libjpeg-turbo-devel libjpeg-devel libpng-devel \
    libtool libuuid-devel uuid-devel make cmake ffmpeg ffmpeg-devel freerdp-devel \
    pango-devel libssh2-devel libtelnet-devel libvncserver-devel libwebsockets-devel \
    pulseaudio-libs-devel openssl-devel compat-openssl11 libvorbis-devel \
    libwebp-devel libgcrypt-devel

# === JAVA & TOMCAT ===
echoyellow ">>> Installing Java and Tomcat..."
sudo dnf install -y java-11-openjdk-devel tomcat

# === MARIADB SETUP ===
echoyellow ">>> Installing and securing MariaDB..."
MYSQL_ROOT_PASS=$(openssl rand -base64 16)
SOLUTIONS_DB_PASS=$(openssl rand -base64 16)
sudo dnf install -y mariadb-server
systemctl enable --now mariadb

mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASS}';"
mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "DELETE FROM mysql.user WHERE User='';"
mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "DROP DATABASE IF EXISTS test;"
mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "FLUSH PRIVILEGES;"

mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "CREATE DATABASE guacamoledb;"
mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "CREATE USER 'guacamole'@'localhost' IDENTIFIED BY '${SOLUTIONS_DB_PASS}';"
mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "GRANT SELECT,INSERT,UPDATE,DELETE ON guacamoledb.* TO 'guacamole'@'localhost';"
mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "FLUSH PRIVILEGES;"

# === GUACAMOLE SERVER INSTALL ===
echoyellow ">>> Installing Guacamole server..."
cd /usr/src
wget https://dlcdn.apache.org/guacamole/1.5.5/source/guacamole-server-1.5.5.tar.gz

tar -xf guacamole-server-1.5.5.tar.gz
cd guacamole-server-*/
./configure --with-systemd-dir=/etc/systemd/system/
make && make install
ldconfig

mkdir -p /etc/guacamole/
cat <<EOF > /etc/guacamole/guacd.conf
[server]
bind_host = 127.0.0.1
bind_port = 4822
EOF

systemctl daemon-reload
systemctl enable --now guacd

# === GUACAMOLE WEBAPP ===
echoyellow ">>> Deploying Guacamole web app..."
cd /usr/src
wget https://dlcdn.apache.org/guacamole/1.5.5/binary/guacamole-1.5.5.war
cp guacamole-1.5.5.war /var/lib/tomcat/webapps/guacamole.war
systemctl restart tomcat

# === DATABASE AUTH MODULE ===
echoyellow ">>> Setting up database authentication..."
mkdir -p /etc/guacamole/{extensions,lib}
echo "GUACAMOLE_HOME=/etc/guacamole" | tee -a /etc/sysconfig/tomcat

cd /usr/src
wget https://downloads.apache.org/guacamole/1.5.5/binary/guacamole-auth-jdbc-1.5.5.tar.gz
tar -xf guacamole-auth-jdbc-1.5.5.tar.gz
mv guacamole-auth-jdbc-1.5.5/mysql/guacamole-auth-jdbc-mysql-1.5.5.jar /etc/guacamole/extensions/

cat guacamole-auth-jdbc-1.5.5/mysql/schema/*.sql | mariadb -uroot -p"${MYSQL_ROOT_PASS}" guacamoledb

cd /usr/src
wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-j-8.0.33.tar.gz
tar -xf mysql-connector-j-8.0.33.tar.gz
mv mysql-connector-j-8.0.33/mysql-connector-j-8.0.33.jar /etc/guacamole/lib/

cat <<EOF > /etc/guacamole/guacamole.properties
mysql-hostname: localhost
mysql-database: guacamoledb
mysql-username: guacamole
mysql-password: ${SOLUTIONS_DB_PASS}
EOF

systemctl restart tomcat

# === OPTIONAL: NGINX PROXY ===
echoyellow ">>> Installing and configuring NGINX (optional)..."
dnf install -y nginx certbot python3-certbot-nginx

cat <<EOF > /etc/nginx/conf.d/guacamole.conf
server {
    listen 80;
    server_name ${SERVER_IP};

    access_log /var/log/nginx/guacamole-access.log;
    error_log /var/log/nginx/guacamole-error.log;

    location / {
        proxy_pass http://127.0.0.1:8080/guacamole/;
        proxy_buffering off;
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$http_connection;
        access_log off;
    }
}
EOF

nginx -t && systemctl restart nginx

echogreen ""
echogreen "Guacamole Server installed successfully!"
echogreen "--------------------------------------"
echogreen "Save this information"
echogreen "Access it via: http://${SERVER_IP}/guacamole"
echogreen "Root DB Password: ${MYSQL_ROOT_PASS}"
echogreen "Guacamole DB User: guacamole"
echogreen "Guacamole DB Password: ${SOLUTIONS_DB_PASS}"
echogreen ""
echogreen "--------------------------------------"
echogreen "More scripts: https://github.com/source-saraiva/easyinstall/"
echogreen "--------------------------------------"
