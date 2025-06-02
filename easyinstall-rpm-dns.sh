#!/bin/bash

# === Style Functions ===
echoyellow() { echo -e "\e[33m$1\e[0m"; }
echored()    { echo -e "\e[31m$1\e[0m"; }
echogreen()  { echo -e "\e[32m$1\e[0m"; }
echoblue()   { echo -e "\e[94m$1\e[0m"; }
echocyan()   { echo -e "\e[36m$1\e[0m"; }

# Function for mandatory input (by reference)
prompt_nonempty() {
    local __resultvar=$1
    local prompt="$2"
    local value=""
    while [[ -z "$value" ]]; do
        read -p "$prompt" value
        if [[ -z "$value" ]]; then
            echored "Input cannot be empty. Please try again."
        fi
    done
    eval $__resultvar="'$value'"
}

echoyellow "=== Easy Install Script (DNS Server Setup with BIND9) ==="
echoyellow "This script will install and configure a BIND9 DNS server on RPM-based systems."

# Detect local IP and suggested domain
DEFAULT_IP=$(ip route get 1.1.1.1 | awk '/src/ {print $7; exit}')
DOMAIN_SUGGEST=$(hostname -d)

# Prompt user for inputs with suggestions
prompt_nonempty DOMAIN "Enter your domain name (e.g., ${DOMAIN_SUGGEST}): "
read -p "Enter your DNS server IP [default: ${DEFAULT_IP}]: " DNS_IP
DNS_IP=${DNS_IP:-$DEFAULT_IP}
prompt_nonempty ADMIN_EMAIL "Enter admin email (e.g., admin.${DOMAIN_SUGGEST} - replace @ with .): "

ZONE_FILE="/var/named/${DOMAIN}.zone"

echoyellow ">>> Installing BIND DNS server package..."
dnf -y install bind bind-utils

echoyellow ">>> Backing up existing configuration if present..."
if [ -f /etc/named.conf ]; then
    cp /etc/named.conf /etc/named.conf.bak.$(date +%F-%H%M%S)
fi

echoyellow ">>> Writing named.conf configuration..."
cat <<EOF > /etc/named.conf
options {
    directory "/var/named";
    listen-on port 53 { any; };
    allow-query     { any; };
    recursion no;
};

zone "${DOMAIN}" IN {
    type master;
    file "${DOMAIN}.zone";
    allow-update { none; };
};
EOF

echoyellow ">>> Creating zone file for ${DOMAIN}..."
cat <<EOF > "${ZONE_FILE}"
\$TTL 86400
@   IN  SOA     ns1.${DOMAIN}. ${ADMIN_EMAIL}. (
                $(date +%Y%m%d)01 ; Serial
                3600       ; Refresh
                1800       ; Retry
                1209600    ; Expire
                86400 )    ; Minimum TTL
;
@       IN  NS      ns1.${DOMAIN}.
ns1     IN  A       ${DNS_IP}
EOF

echoyellow ">>> Setting permissions for zone file..."
chown root:named "${ZONE_FILE}"
chmod 640 "${ZONE_FILE}"

echoyellow ">>> Enabling and starting named service..."
systemctl enable --now named

echoyellow ">>> Configuring firewall to allow DNS traffic..."
firewall-cmd --add-service=dns
firewall-cmd --runtime-to-permanent

echogreen ""
echogreen "DNS Server installed successfully!"
echogreen "--------------------------------------"
echogreen "Save this information"
echogreen "To test your DNS server, use:"
echogreen "    dig @${DNS_IP} SOA ${DOMAIN}"
echogreen "    dig -x ${DNS_IP}"
echogreen "To check service status:"
echogreen "    systemctl status named"
echogreen "To restart DNS server:"
echogreen "    systemctl restart named"
echogreen "Zone files are located in:"
echogreen "    /var/named/"
echogreen "Configuration file:"
echogreen "   cat /etc/named.conf"
echogreen ""
echogreen "--------------------------------------"
echogreen "More scripts @ https://github.com/source-saraiva/easyinstall/"
echogreen "--------------------------------------"
