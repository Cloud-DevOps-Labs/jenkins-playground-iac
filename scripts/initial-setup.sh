#!/bin/bash

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Iniciando configuración del entorno Jenkins...${NC}"

# Directorio para almacenar claves SSH
KEYS_DIR="./ssh-keys"
mkdir -p $KEYS_DIR

# Generar par de claves para Jenkins Agent
echo -e "${YELLOW}Generando claves SSH para Jenkins Agent...${NC}"
ssh-keygen -t rsa -b 4096 -f "$KEYS_DIR/jenkins_agent" -N "" -C "jenkins-agent"

# Generar par de claves para Webserver
echo -e "${YELLOW}Generando claves SSH para Webserver...${NC}"
ssh-keygen -t rsa -b 4096 -f "$KEYS_DIR/webserver" -N "" -C "webserver"

# Actualizar docker-compose.yaml con la clave pública del agente
echo -e "${YELLOW}Actualizando docker-compose.yaml con la clave pública del agente...${NC}"
AGENT_PUBLIC_KEY=$(cat "$KEYS_DIR/jenkins_agent.pub")
sed -i "s|JENKINS_AGENT_SSH_PUBKEY=.*|JENKINS_AGENT_SSH_PUBKEY=${AGENT_PUBLIC_KEY}|" docker-compose.yaml

# Crear archivo de configuración para Nginx
echo -e "${YELLOW}Creando configuración de Nginx...${NC}"
mkdir -p nginx-conf
cat > nginx-conf/default.conf << 'EOL'
server {
    listen 80;
    server_name localhost;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
        try_files $uri $uri/ /index.html;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
EOL

# Crear archivo con instrucciones post-setup
cat > POST_SETUP_INSTRUCTIONS.txt << 'EOL'
=== Instrucciones Post-Setup ===

1. Contraseña inicial de Jenkins:
   docker exec jenkins-master cat /var/jenkins_home/secrets/initialAdminPassword

2. Configurar credenciales en Jenkins:
   - Ir a "Manage Jenkins" > "Manage Credentials"
   - Añadir las siguientes credenciales SSH:
     * ID: jenkins-agent-key
       Descripción: "Jenkins Agent SSH Key"
       Usuario: jenkins
       Clave privada: Contenido de ./ssh-keys/jenkins_agent

     * ID: webserver-key
       Descripción: "Webserver SSH Key"
       Usuario: root
       Clave privada: Contenido de ./ssh-keys/webserver

3. Configurar el nodo Jenkins:
   - Ir a "Manage Jenkins" > "Manage Nodes"
   - Añadir nodo "jenkins-agent"
   - Usar las credenciales "jenkins-agent-key"
   - Host: jenkins-agent
   - Puerto: 22

4. Instalar plugins necesarios:
   - Git
   - Pipeline
   - SSH Agent
   - NodeJS Plugin

5. Configurar herramientas:
   - Ir a "Manage Jenkins" > "Global Tool Configuration"
   - Configurar NodeJS (versión LTS)
   - Configurar Git

Las claves SSH se han generado en el directorio ./ssh-keys/
Guarde estas claves de forma segura y elimínelas del servidor después de la configuración.

EOL

# Establecer permisos correctos para las claves
chmod 600 "$KEYS_DIR/jenkins_agent"
chmod 600 "$KEYS_DIR/webserver"
chmod 644 "$KEYS_DIR/jenkins_agent.pub"
chmod 644 "$KEYS_DIR/webserver.pub"

echo -e "${GREEN}Configuración inicial completada.${NC}"
echo -e "${YELLOW}Por favor, revise el archivo POST_SETUP_INSTRUCTIONS.txt para los siguientes pasos.${NC}"

# Crear un archivo .env con valores por defecto
cat > .env << 'EOL'
JENKINS_ADMIN_ID=admin
JENKINS_ADMIN_PASSWORD=changeme2024
JENKINS_URL=http://localhost:8080/
DOCKER_HOST=unix:///var/run/docker.sock
EOL

echo -e "${YELLOW}Se ha creado un archivo .env con valores por defecto.${NC}"
echo -e "${RED}¡IMPORTANTE! Modifique el archivo .env con sus propias credenciales antes de iniciar los contenedores.${NC}"

