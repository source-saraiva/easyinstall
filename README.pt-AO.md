[![en](https://img.shields.io/badge/lang-en-red.svg)](https://github.com/source-saraiva/easyinstall/blob/main/README.md)
[![pt-AO](https://img.shields.io/badge/lang-pt--ao-green.svg)](https://github.com/source-saraiva/easyinstall/blob/main/README.pt-AO.md)

Claro! Aqui está a tradução para **português de Portugal**:

---

````markdown
# 🧰 easyinstall

**easyinstall** é uma coleção de scripts que simplifica a instalação e configuração de pacotes comuns em servidores Linux. Inspirado no assistente "Adicionar Funções e Funcionalidades" do Microsoft Windows Server, o easyinstall oferece uma experiência semelhante para administradores de sistemas Linux.

## ✨ Objetivo

Configurar um servidor Linux para funções específicas (como DHCP, DNS, gestão de ativos de TI, etc.) geralmente requer muitos passos manuais. O **easyinstall** automatiza estas tarefas, permitindo preparar o seu servidor com apenas alguns comandos.

## ✅ Funcionalidades

* 🚀 Instalação com um único comando para vários tipos de servidor
* 📦 Instalação automática para:

  * **Servidor DHCP**
  * **Servidor GLPI** (Gestão de Ativos de TI)
  * **Servidor BIND9** (DNS)
  * *(Mais opções brevemente!)*
* ⚙️ Base de scripts limpa, modular e facilmente extensível
* 🧪 Compatível com sistemas baseados em RHEL e, futuramente, com sistemas baseados em Debian
* 🧑‍💻 Ideal para sysadmins, estudantes e equipas de TI em ambientes de laboratório ou produção

## 📋 Exemplo de Utilização

```bash
# Conecte-se ao seu servidor como root via SSH
ssh root@seu.servidor

# Descarregue e execute o script de instalação
# Para sistemas RPM
u=https://raw.githubusercontent.com/source-saraiva/easyinstall/main/easyinstall-rpm-glpi.sh; (curl -ksS "$u" -o ei.sh || wget -q "$u" -O ei.sh) && bash ei.sh

# Para sistemas Debian
u=https://raw.githubusercontent.com/source-saraiva/easyinstall/main/easyinstall-deb-glpi.sh; (curl -ksS "$u" -o ei.sh || wget -q "$u" -O ei.sh) && bash ei.sh
````

## 📦 Funções Disponíveis

### Servidor DHCP

**Sistemas baseados em RPM**

```bash
u=https://raw.githubusercontent.com/source-saraiva/easyinstall/main/easyinstall-rpm-dhcp.sh; (curl -ksS "$u" -o ei.sh || wget -q "$u" -O ei.sh) && bash ei.sh
```

