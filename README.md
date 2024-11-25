# jenkins-playground-iac | Práctica CI/CD con Jenkins

Este repositorio contiene una configuración completa para implementar un pipeline de CI/CD utilizando Jenkins, Docker y Nginx. El proyecto está diseñado con fines educativos para demostrar las mejores prácticas en integración y despliegue continuo.

## Arquitectura

El proyecto consta de tres componentes principales dockerizados:

- 🔵 **Jenkins Master**: Servidor principal de Jenkins
- 🟢 **Jenkins Agent**: Nodo de ejecución para los jobs
- 🌐 **Nginx Server**: Servidor web para el despliegue

```mermaid
graph LR
    A[Jenkins Master] -->|Gestiona| B[Jenkins Agent]
    B -->|Despliega en| C[Nginx Server]
    D[Git Repository] -->|Código| B
```

## Requisitos Previos

- Docker y Docker Compose v2.x o superior
- Git
- Acceso a puertos 8080 (Jenkins) y 80 (Nginx)

## Configuración Inicial

### 1. Clonar los Repositorios

```bash
# Clonar repositorio de infraestructura (este)
git clone https://github.com/Cloud-DevOps-Labs/jenkins-playground-iac

# Clonar repositorio de la aplicación web
https://github.com/Cloud-DevOps-Labs/jenkins-playground-app
```

### 2. Preparar el Entorno

```bash
cd jenkins-playground-iac

# Dar permisos de ejecución a los scripts de configuración
chmod +x scripts/*.sh

# Ejecutar script de configuración inicial
./scripts/initial-setup.sh
```

### 3. Iniciar los Contenedores

```bash
docker-compose up -d
```

```bash

# Configurar el agente para que tenga las dependencias
make setup-agent

```


### 4. Configuración de Jenkins

#### 4.1 Obtener la Contraseña Inicial
```bash
docker exec jenkins-master cat /var/jenkins_home/secrets/initialAdminPassword
```

#### 4.2 Configuración Inicial de Jenkins
1. Acceder a http://localhost:8080
2. Introducir la contraseña inicial obtenida
3. Instalar los plugins recomendados:
   - Git plugin
   - Pipeline
   - SSH Agent
   - NodeJS Plugin

#### 4.3 Configurar Credenciales en Jenkins
1. Ir a "Manage Jenkins" > "Manage Credentials"
2. Añadir credenciales SSH para Jenkins Agent:
   - Kind: SSH Username with private key
   - ID: jenkins-agent-key
   - Username: jenkins
   - Private Key: [Contenido de ./ssh-keys/jenkins_agent]

3. Añadir credenciales SSH para Webserver:
   - Kind: SSH Username with private key
   - ID: webserver-key
   - Username: root
   - Private Key: [Contenido de ./ssh-keys/webserver]

#### 4.4 Configurar el Nodo Jenkins
1. Ir a "Manage Jenkins" > "Manage Nodes"
2. Añadir nuevo nodo:
   - Node name: jenkins-agent
   - Permanent Agent: Yes
   - Remote root directory: /home/jenkins/agent
   - Labels: jenkins-agent
   - Launch method: SSH
   - Host: jenkins-agent
   - Credentials: jenkins-agent-key
   - Host Key Verification Strategy: Non verifying

#### 4.5 Configurar Herramientas
1. Ir a "Manage Jenkins" > "Global Tool Configuration"
2. Configurar NodeJS:
   - Nombre: NodeJS
   - Versión: LTS
   - Instalación automática: Yes

3. Configurar Git:
   - Nombre: Default
   - Path to Git executable: git

### 5. Crear el Pipeline

1. Ir a Jenkins Dashboard
2. Crear "New Item"
3. Seleccionar "Pipeline"
4. Configurar pipeline:
   - Pipeline from SCM
   - SCM: Git
   - Repository URL: https://github.com/Cloud-DevOps-Labs/jenkins-playground-app.git
   - Branch to build: */main
   - Script Path: Jenkinsfile

## Verificación

1. Hacer un commit en el repositorio web-sample
2. Verificar que el pipeline se ejecuta automáticamente
3. Comprobar la web desplegada en http://localhost:80

## Estructura del Proyecto

```
jenkins-cicd/
├── docker-compose.yaml     # Configuración de contenedores
├── scripts/
│   └── initial-setup.sh    # Script de configuración inicial
├── nginx-conf/             # Configuración de Nginx
│   └── default.conf
├── ssh-keys/              # Claves SSH generadas
└── README.md
```

## Consideraciones de Seguridad

- Las claves SSH se generan localmente durante la configuración inicial
- Los secretos y credenciales se gestionan a través del sistema de credenciales de Jenkins
- Se aplica el principio de mínimo privilegio en todas las configuraciones
- Las claves SSH deben rotarse periódicamente en un entorno de producción

## Solución de Problemas

### El agente Jenkins no se conecta
Verificar:
1. Las credenciales SSH están correctamente configuradas
2. El contenedor del agente está en ejecución
3. La red de Docker está funcionando correctamente

### Fallos en el despliegue web
Verificar:
1. Los permisos en el directorio web de Nginx
2. La conectividad SSH entre el agente y el servidor web
3. Los logs de Nginx para errores específicos

## Referencias

- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Jenkins SSH Agent Plugin](https://plugins.jenkins.io/ssh-agent/)
- [Nginx Documentation](https://nginx.org/en/docs/)

