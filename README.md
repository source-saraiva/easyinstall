
[![en](https://img.shields.io/badge/lang-en-red.svg)](https://github.com/source-saraiva/easyinstall/blob/main/README.md)
[![pt-AO](https://img.shields.io/badge/lang-pt--ao-green.svg)](https://github.com/source-saraiva/easyinstall/blob/main/README.pt-AO.md)


# 🧰 easyinstall

**easyinstall** is a collection of scripts that simplifies the installation and configuration of common packages on Linux servers. Inspired by the "Add Roles and Features" wizard in Microsoft Windows Server, easyinstall offers a similar experience for Linux system administrators.

## ✨ Purpose

Setting up a Linux server for specific roles (such as DHCP, DNS, IT asset management, etc.) usually requires many manual steps. **easyinstall** automates these tasks, allowing you to prepare your server with just a few commands.

## ✅ Features

* 🚀 One-command installation for various server roles
* 📦 Automated installation for:

  * **DHCP Server**
  * **GLPI Server** (IT Asset Management)
  * **BIND9 Server** (DNS)
  * *and many more options!*
* ⚙️ Clean, modular, and easily extensible script base
* 🧪 Compatible with RHEL-based and in the future Debian-based systems
* 🧑‍💻 Ideal for sysadmins, students, and IT teams in labs or production environments

## 📋 Usage Example

```bash
# Connect to your server via SSH as root or a user with sudo privileges 
ssh root@your.server

# Download & Run the installation script
# For RPM
u=https://raw.githubusercontent.com/source-saraiva/easyinstall/main/easyinstall-rpm-glpi.sh; (curl -ksS "$u" -o ei.sh || wget -q "$u" -O ei.sh) && sudo bash ei.sh

# For Deb
u=https://raw.githubusercontent.com/source-saraiva/easyinstall/main/easyinstall-deb-glpi.sh; (curl -ksS "$u" -o ei.sh || wget -q "$u" -O ei.sh) && sudo bash ei.sh
```
## 📦 Available Roles

RPM scripts tested on almalinux 9 - [AlmaLinux OS 9.6 Minimal ISO](https://almalinux.org/get-almalinux/) 

### DHCP Server
**RPM-based systems**
```bash
u=https://raw.githubusercontent.com/source-saraiva/easyinstall/main/easyinstall-rpm-dhcp.sh; (curl -ksS "$u" -o ei.sh || wget -q "$u" -O ei.sh) && sudo bash ei.sh
```

### DNS Server
**RPM-based systems**
```bash
u=https://raw.githubusercontent.com/source-saraiva/easyinstall/main/easyinstall-rpm-dns.sh; (curl -ksS "$u" -o ei.sh || wget -q "$u" -O ei.sh) && sudo bash ei.sh
```

### Guacamole Server
**RPM-based systems**
```bash
u=https://raw.githubusercontent.com/source-saraiva/easyinstall/main/easyinstall-rpm-guacamole.sh; (curl -ksS "$u" -o ei.sh || wget -q "$u" -O ei.sh) && sudo bash ei.sh
```
Credits:
[r00t](https://idroot.us/install-apache-guacamole-almalinux-9) , [Christian Wells](https://shape.host/resources/how-to-set-up-a-remote-desktop-gateway-with-apache-guacamole-on-almalinux-9)
