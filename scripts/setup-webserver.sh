#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SSH_KEY_PATH="/tmp/webserver.pub"

echo -e "${GREEN}Configurando servidor web...${NC}"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Este script debe ejecutarse como root${NC}"
    exit 1
fi

if [ ! -f "$SSH_KEY_PATH" ]; then
    echo -e "${RED}Error: No existe el archivo de clave pública en $SSH_KEY_PATH${NC}"
    echo -e "${RED}Ejecuta primero el script initial-setup.sh${NC}"
    exit 1
fi

check_result() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✔ $1${NC}"
    else
        echo -e "${RED}✘ Error: $1${NC}"
        exit 1
    fi
}

echo -e "${YELLOW}Actualizando sistema...${NC}"
apt-get update
apt-get upgrade -y
check_result "Actualización del sistema"

echo -e "${YELLOW}Instalando SSH y utilidades...${NC}"
apt-get install -y openssh-server sudo
check_result "Instalación de SSH"

echo -e "${YELLOW}Configurando SSH...${NC}"
mkdir -p /var/run/sshd
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
echo 'AuthorizedKeysFile .ssh/authorized_keys' >> /etc/ssh/sshd_config

mkdir -p /root/.ssh
chmod 700 /root/.ssh
touch /root/.ssh/authorized_keys
cat "$SSH_KEY_PATH" >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
check_result "Configuración SSH y copia de clave"

echo -e "${YELLOW}Iniciando servicio SSH...${NC}"
service ssh start
check_result "Inicio del servicio SSH"

echo -e "${YELLOW}Verificando instalación...${NC}"
if service ssh status | grep -q "sshd is running"; then
    echo -e "${GREEN}✔ Servicio SSH activo y funcionando${NC}"
else
    echo -e "${RED}✘ Error: SSH no está ejecutándose${NC}"
    exit 1
fi

echo -e "${YELLOW}Limpiando sistema...${NC}"
apt-get clean
apt-get autoremove -y
rm -rf /var/lib/apt/lists/*
check_result "Limpieza del sistema"

echo -e "${GREEN}✨ Configuración del servidor web completada${NC}"
echo -e "${YELLOW}Puerto SSH: 22${NC}"


