#!/bin/bash

# === easyinstall - solution: DHCP Server ===

# Color functions
echocyan()   { echo -e "\e[36m$1\e[0m"; }
echogreen()  { echo -e "\e[32m$1\e[0m"; }
echored()    { echo -e "\e[31m$1\e[0m"; }

clear
echocyan ""
echocyan "                   .--------------."
echocyan "                   | Easy Install |"
echocyan "                   '--------------'"
echocyan ""

# Header
echocyan "=============================================================="
echocyan "Solution: DHCP Server"
echocyan "Target: RPM-based systems"
echocyan "=============================================================="
echo ""

## === AUTODETECT & VALIDATION ===

# Prompt with default and enforce non-empty input
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

# Detect network interface and current settings
ACTIVE_IFACE=$(ip route | grep '^default' | awk '{print $5}')
USER_IP=$(ip -4 addr show "$ACTIVE_IFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
GATEWAY=$(ip route | grep '^default' | awk '{print $3}')
DOMAIN_SUGGESTED=$(hostname -d)
DNS_SUGGESTED="$USER_IP"

# Calculate defaults from IP
IFS='.' read -r IP1 IP2 IP3 IP4 <<< "$USER_IP"
SUBNET_BASE="$IP1.$IP2.$IP3"
SUBNET_DEFAULT="$SUBNET_BASE.0"
NETMASK_DEFAULT="255.255.255.0"
BROADCAST_DEFAULT="$SUBNET_BASE.255"
RANGE_START_DEFAULT="$SUBNET_BASE.100"
RANGE_END_DEFAULT="$SUBNET_BASE.254"
DEFAULT_LEASE_DEFAULT="86400"
MAX_LEASE_DEFAULT="604800"

# Display detected network info
echocyan "Detected IP address: $USER_IP on interface: $ACTIVE_IFACE"
echocyan "Suggested values are based on current network configuration"
echo""
# Prompt user for DHCP configuration inputs
SUBNET=$(prompt_nonempty_default "Enter subnet IP" "$SUBNET_DEFAULT")
NETMASK=$(prompt_nonempty_default "Enter subnet mask" "$NETMASK_DEFAULT")
BROADCAST=$(prompt_nonempty_default "Enter broadcast address" "$BROADCAST_DEFAULT")
RANGE_START=$(prompt_nonempty_default "Enter IP range start" "$RANGE_START_DEFAULT")
RANGE_END=$(prompt_nonempty_default "Enter IP range end" "$RANGE_END_DEFAULT")
DEFAULT_LEASE=$(prompt_nonempty_default "Enter default lease time (in seconds)" "$DEFAULT_LEASE_DEFAULT")
MAX_LEASE=$(prompt_nonempty_default "Enter max lease time (in seconds)" "$MAX_LEASE_DEFAULT")
ROUTER=$(prompt_nonempty_default "Enter gateway/router IP" "$GATEWAY")
DOMAIN_NAME=$(prompt_nonempty_default "Enter your domain name" "${DOMAIN_SUGGESTED:-mydomain.local}")
DNS_SERVER=$(prompt_nonempty_default "Enter your DNS server 1" "$DNS_SUGGESTED")
DNS_SERVER2=$(prompt_nonempty_default "Enter your DNS server 2" "8.8.4.4")

## === DHCP ===

# Install DHCP server package
echocyan "Installing DHCP server package..."
dnf -y install dhcp-server

# Backup existing configuration
echocyan "Backing up existing DHCP configuration..."
if [ -f /etc/dhcp/dhcpd.conf ]; then
    cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.bak.$(date +%F-%H%M%S)
fi

# Write new configuration to dhcpd.conf
echocyan "Writing new DHCP configuration..."
cat <<EOF > /etc/dhcp/dhcpd.conf
# DHCP Configuration generated by EasyInstall script
option domain-name "${DOMAIN_NAME}";
option domain-name-servers ${DNS_SERVER}, ${DNS_SERVER2};
default-lease-time ${DEFAULT_LEASE};
max-lease-time ${MAX_LEASE};
authoritative;

subnet ${SUBNET} netmask ${NETMASK} {
    range dynamic-bootp ${RANGE_START} ${RANGE_END};
    option broadcast-address ${BROADCAST};
    option routers ${ROUTER};
}
EOF

# Enable and start DHCP service
echocyan "Enabling and starting DHCP service..."
systemctl enable --now dhcpd

# Configure firewall to allow DHCP
echocyan "Configuring firewall to allow DHCP traffic..."
firewall-cmd --add-service=dhcp
firewall-cmd --runtime-to-permanent

# Final user instructions
echogreen ""
echogreen "DHCP Server installed and configured successfully"
echo
echogreen "--------------------------------------------------"
echogreen "SAVE THIS INFORMATION"
echogreen "--------------------------------------------------"
echogreen "To check service status:"
echogreen "    systemctl status dhcpd"
echogreen "To view live logs:"
echogreen "    journalctl -u dhcpd -f"
echogreen "To view active leases:"
echogreen "    cat /var/lib/dhcpd/dhcpd.leases"
echogreen "Configuration file:"
echogreen "    /etc/dhcp/dhcpd.conf"
echogreen ""
echogreen "For more scripts, visit:"
echogreen "    https://github.com/source-saraiva/easyinstall/"
echogreen "--------------------------------------------------"
