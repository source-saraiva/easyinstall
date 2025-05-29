# 🧰 easyinstall

**easyinstall** é uma coleção de scripts que simplifica a instalação e configuração de pacotes comuns em servidores Linux. Inspirado no assistente "Adicionar Funções e Recursos" do Microsoft Windows Server, o easyinstall oferece uma experiência semelhante para administradores de sistemas Linux.

## ✨ Propósito

Configurar um servidor Linux para funções específicas (como DHCP, DNS, gestão de ativos de TI, etc.) normalmente exige muitos passos manuais. O **easyinstall** automatiza essas tarefas, permitindo preparar seu servidor com apenas alguns comandos.

## ✅ Funcionalidades

- 🚀 Instalação com um único comando para diversas funções de servidor
- 📦 Instalação automática para:
  - **Servidor DHCP**
  - **Servidor GLPI** (Gestão de Ativos de TI)
  - **Servidor BIND9** (DNS)
  - *(Mais em breve!)*  
- ⚙️ Base de scripts limpa, modular e fácil de expandir
- 🧪 Compatível com sistemas baseados em Debian e RHEL
- 🧑‍💻 Ideal para sysadmins, estudantes e equipes de TI em laboratórios ou ambientes de produção

## 📋 Exemplo de Uso

```bash
# Conecte-se ao seu servidor como root via SSH
ssh root@seu.servidor

# Baixe o script de instalação
curl -O https://raw.githubusercontent.com/source-saraiva/easyinstall/main/easyinstall-deb-glpi.sh
or
curl -O https://raw.githubusercontent.com/source-saraiva/easyinstall/main/easyinstall-rpm-glpi.sh

# Execute o script
chmod +x easyinstall-deb-glpi.sh
bash easyinstall-deb-glpi.sh
or
chmod +x easyinstall-rpm-glpi.sh
bash easyinstall-rpm-glpi.sh
