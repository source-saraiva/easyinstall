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

mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "CREATE DATABASE fossbilling_db;"
mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "CREATE OR REPLACE USER 'fossbilling_user'@'localhost' IDENTIFIED BY '${SOLUTIONS_DB_PASS}';"
mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON fossbilling_db.* TO 'fossbilling_user'@'localhost';"
mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "FLUSH PRIVILEGES;"




# === PHP ===
echoyellow  "Installing and configuring php ..."
sudo dnf install -y https://rpms.remirepo.net/enterprise/remi-release-9.rpm
sudo dnf module reset -y php
sudo dnf module enable -y php:remi-8.2 -y
sudo dnf install -y php php-cli php-fpm php-common php-mysqlnd php-mbstring php-xml php-zip


# Change file /etc/php.ini
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

# Change file /etc/php-fpm.d/www.conf
PHP_FPM_CONF="/etc/php-fpm.d/www.conf"

# Backup the original www.conf
cp $PHP_FPM_CONF ${PHP_FPM_CONF}.bak

# Change user and group to nginx
sed -i 's/^user\s*=\s*apache/user = nginx/' "$PHP_FPM_CONF"
sed -i 's/^group\s*=\s*apache/group = nginx/' "$PHP_FPM_CONF"


sudo systemctl start php-fpm
sudo systemctl enable php-fpm
echoyellow "PHP-FPM pool configuration updated to use nginx user/group."


# === TOOLS ===
echoyellow  "Installing dependecies..."
sudo dnf install -y dnf-utils wget curl tar unzip nano vim dnf-plugins-core htop


# === NGNIX ===
echoyellow  "Installing Ngnix..."
sudo dnf install -y nginx 
SERVER_IP=$(hostname -I | awk '{print $1}')
echoyellow "Please enter the URL you will use to access FOSSBilling (leave blank to use $(hostname -f)):"
read -r ACCESS_URL
[ -z "$ACCESS_URL" ] && ACCESS_URL=$(hostname -f)
cat <<EOF | sudo tee /etc/nginx/conf.d/fossbilling.conf
server {
    listen 80;
    server_name ${SERVER_IP} ${ACCESS_URL};

    access_log /var/log/nginx/fossbilling_access.log;
    error_log /var/log/nginx/fossbilling_error.log;

$(cat <<'INNER'
    set $root_path /var/www/fossbilling;

    index index.html index.htm index.php;
    root $root_path;
    try_files $uri $uri/ @rewrite;
    sendfile off;

    include /etc/nginx/mime.types;

    location ~* \.(ini|sh|inc|bak|twig|sql)$ {
        return 404;
    }

    location ~ /\.(?!well-known\/) {
        return 404;
    }

    location ~* /uploads/.*\.php$ {
        return 404;
    }

    location ~* /data/ {
        return 404;
    }

    location @rewrite {
        rewrite ^/page/(.*)$ /index.php?_url=/custompages/$1;
        rewrite ^/(.*)$ /index.php?_url=/$1;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php-fpm/www.sock;
        fastcgi_param PATH_INFO       $fastcgi_path_info;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_intercept_errors on;
        include fastcgi_params;
    }

    location ~* ^/(css|img|js|flv|swf|download)/(.+)$ {
        root $root_path;
        expires off;
    }
}
INNER
)
EOF

# SELINUX
sudo dnf install -y python3-policycoreutils selinux-policy-devel 

sudo semanage fcontext -a -t httpd_sys_content_t '/var/www/html(/.*)?'
sudo restorecon -Rv /var/www/html
sudo setsebool -P httpd_can_network_connect on
sudo setsebool -P httpd_can_sendmail on
sudo setsebool -P httpd_can_network_connect_db on

sudo nginx -t
sudo systemctl start nginx
sudo systemctl enable nginx



# === FOSSBILLING ===
sudo mkdir -p /var/www/fossbilling
cd /tmp
if [ ! -f "FOSSBilling.zip" ]; then
sudo curl https://fossbilling.org/downloads/stable -L --output FOSSBilling.zip
else
  echogreen "FOSSBilling.zip already exists. Skipping download."
fi

sudo unzip FOSSBilling.zip -d /var/www/fossbilling
sudo chown -R nginx:nginx /var/www/fossbilling

# === Meet all system requirements ===
sudo dnf install -y php-intl php-gd php-pecl-imagick
php -m | grep -E 'intl|imagick|gd'


cd /var/www/fossbilling/
find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;

sudo systemctl restart php-fpm
sudo systemctl restart nginx



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