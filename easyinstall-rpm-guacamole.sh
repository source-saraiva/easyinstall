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
wget https://dlcdn.apache.org/guacamole/1.5.5/source/guacamole-server-1.5.5.tar.gz
tar -xf guacamole-server-1.5.5.tar.gz
cd guacamole-server-1.5.5/
./configure --with-systemd-dir=/etc/systemd/system/
make
sudo make install
sudo ldconfig
sudo systemctl enable --now guacd

cd /tmp
wget https://dlcdn.apache.org/guacamole/1.5.5/binary/guacamole-1.5.5.war
sudo mkdir -p /etc/guacamole/{extensions,lib}
sudo cp guacamole-1.5.5.war /var/lib/tomcat/webapps/guacamole.war
sudo ln -s /etc/guacamole /usr/share/tomcat/.guacamole
echo "GUACAMOLE_HOME=/etc/guacamole" | sudo tee -a /etc/default/tomcat

# === DATABASE AUTH MODULE ===
cd /tmp
wget https://dlcdn.apache.org/guacamole/1.5.5/binary/guacamole-auth-jdbc-1.5.5.tar.gz
tar -xf guacamole-auth-jdbc-1.5.5.tar.gz

wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-j-8.0.32.tar.gz
tar -xf mysql-connector-j-8.0.32.tar.gz
sudo cp mysql-connector-j-8.0.32/mysql-connector-j-8.0.32.jar /etc/guacamole/lib/
sudo cp guacamole-auth-jdbc-1.5.5/mysql/guacamole-auth-jdbc-mysql-1.5.5.jar /etc/guacamole/extensions/

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
echo -e "\e[1;33m>>> Guacamole is available at: http://${SERVER_IP}:8080/guacamole\e[0m"
