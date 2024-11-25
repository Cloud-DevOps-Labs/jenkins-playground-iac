#!/bin/bash

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Iniciando configuración del Jenkins Agent...${NC}"

# Verificar si se está ejecutando como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Este script debe ejecutarse como root${NC}"
    exit 1
fi

# Función para verificar el resultado de los comandos
check_result() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✔ $1 completado${NC}"
    else
        echo -e "${RED}✘ Error: $1 falló${NC}"
        exit 1
    fi
}

# Actualizar sistema
echo -e "${YELLOW}Actualizando sistema...${NC}"
apt-get update
apt-get upgrade -y
check_result "Actualización del sistema"

# Instalar dependencias básicas
echo -e "${YELLOW}Instalando dependencias básicas...${NC}"
apt-get install -y \
    curl \
    wget \
    git \
    zip \
    unzip \
    build-essential \
    ca-certificates \
    gnupg
check_result "Instalación de dependencias básicas"

# Instalar Node.js y npm
echo -e "${YELLOW}Instalando Node.js y npm...${NC}"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
NODE_MAJOR=20  # Versión LTS actual
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
apt-get update
apt-get install -y nodejs
check_result "Instalación de Node.js"

# Verificar instalaciones
echo -e "${YELLOW}Verificando instalaciones...${NC}"
node_version=$(node --version)
npm_version=$(npm --version)
git_version=$(git --version)

echo -e "${GREEN}Versiones instaladas:${NC}"
echo "Node.js: $node_version"
echo "npm: $npm_version"
echo "Git: $git_version"

# Instalar dependencias globales de npm
echo -e "${YELLOW}Instalando dependencias globales de npm...${NC}"
npm install -g npm@latest
npm install -g serve
check_result "Instalación de dependencias globales de npm"

# Configurar Git
echo -e "${YELLOW}Configurando Git...${NC}"
git config --system core.longpaths true
git config --system core.autocrlf input
check_result "Configuración de Git"

# Limpiar caché y archivos temporales
echo -e "${YELLOW}Limpiando sistema...${NC}"
apt-get clean
apt-get autoremove -y
rm -rf /var/lib/apt/lists/*
check_result "Limpieza del sistema"

echo -e "${GREEN}✨ Configuración del agente completada exitosamente${NC}"
echo -e "${YELLOW}Recordatorio: Asegúrate de que el agente tenga acceso a los recursos necesarios${NC}"

# Mostrar espacio en disco disponible
echo -e "${YELLOW}Espacio en disco disponible:${NC}"
df -h /

# Mostrar memoria disponible
echo -e "${YELLOW}Memoria disponible:${NC}"
free -h

