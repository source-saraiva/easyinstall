🇬🇧 English | [AO Português](README.pt.md)

# 🧰 easyinstall


**easyinstall** is a curated collection of shell scripts that simplify the installation and configuration of common Linux server packages. Inspired by the "Add Roles and Features" wizard from Microsoft Windows Server, easyinstall aims to bring a similar ease-of-use experience to Linux system administrators.

## ✨ Purpose

Setting up a Linux server for specific roles (like DHCP, DNS, IT asset management, etc.) often involves numerous manual steps. **easyinstall** automates these tasks, making it easy to provision and configure your Linux server with just a few commands.

## ✅ Features

- 🚀 One-command installation of popular Linux server roles
- 📦 Scripted setup for:
  - **DHCP Server**
  - **GLPI Server** (IT Asset Management)
  - **BIND9 Server** (DNS)
  - *(More coming soon!)*  
- ⚙️ Clean, modular, and easily extensible script base
- 🧪 Designed for Debian-based and RHEL-based systems
- 🧑‍💻 Ideal for sysadmins, students, and IT teams setting up test labs or production servers

## 📋 Example Usage

```bash
# Connect to your server as root via SSH
ssh root@your.server

# Download installation script
curl -O https://github.com/source-saraiva/easyinstall/blob/main/easyinstall-glpi.sh

# Run it
chmod +x easyinstall-glpi.sh
bash easyinstall-glpi.sh
