# Variables
JENKINS_MASTER = jenkins-master
JENKINS_AGENT = jenkins-agent
WEBSERVER = webserver
COMPOSE = docker compose

# Colores para output
YELLOW := \033[1;33m
GREEN := \033[0;32m
RED := \033[0;31m
BLUE := \033[0;34m
NC := \033[0m

# Emoji UTF-8
EMOJI_ROCKET := 🚀
EMOJI_GEAR := ⚙️
EMOJI_CHECK := ✅
EMOJI_WARN := ⚠️
EMOJI_TOOL := 🔧
EMOJI_KEY := 🔑

.PHONY: help password up down ps master agent web clean logs setup-agent setup-webserver status

# Target por defecto muestra la ayuda
help:
	@echo "$(BLUE)=====================================$(NC)"
	@echo "$(GREEN)Jenkins CI/CD Environment Management$(NC)"
	@echo "$(BLUE)=====================================$(NC)"
	@echo ""
	@echo "$(YELLOW)Comandos disponibles:$(NC)"
	@echo "$(EMOJI_TOOL) Gestión del entorno:"
	@echo "  make up        - Inicia todos los contenedores"
	@echo "  make down      - Detiene todos los contenedores"
	@echo "  make ps        - Muestra el estado de los contenedores"
	@echo "  make status    - Muestra información detallada del entorno"
	@echo ""
	@echo "$(EMOJI_KEY) Acceso y configuración:"
	@echo "  make password  - Muestra la contraseña inicial de administrador de Jenkins"
	@echo "  make master    - Accede al shell del Jenkins master"
	@echo "  make agent     - Accede al shell del Jenkins agent"
	@echo "  make web       - Accede al shell del servidor web"
	@echo ""
	@echo "$(EMOJI_GEAR) Mantenimiento:"
	@echo "  make logs            - Muestra los logs de todos los contenedores"
	@echo "  make clean           - Limpia todos los recursos (contenedores, volúmenes)"
	@echo "  make setup-agent     - Configura el agente Jenkins con las dependencias necesarias"
	@echo "  make setup-webserver - Configura el servidor web para que tenga ssh"
	@echo ""
	@echo "$(EMOJI_WARN) URLs del proyecto:"
	@echo "  Jenkins: $(BLUE)http://localhost:8080$(NC)"
	@echo "  Web: $(BLUE)http://localhost:80$(NC)"

# Obtener contraseña inicial de Jenkins
password:
	@echo "$(YELLOW)$(EMOJI_KEY) Contraseña inicial de Jenkins:$(NC)"
	@docker exec $(JENKINS_MASTER) cat /var/jenkins_home/secrets/initialAdminPassword
	@echo "$(GREEN)$(EMOJI_CHECK) Accede a Jenkins en http://localhost:8080$(NC)"

# Iniciar contenedores
up:
	@echo "$(YELLOW)$(EMOJI_ROCKET) Iniciando contenedores...$(NC)"
	@$(COMPOSE) up -d
	@echo "$(GREEN)$(EMOJI_CHECK) Contenedores iniciados correctamente$(NC)"
	@$(MAKE) status

# Detener contenedores
down:
	@echo "$(YELLOW)$(EMOJI_WARN) Deteniendo contenedores...$(NC)"
	@$(COMPOSE) down
	@echo "$(GREEN)$(EMOJI_CHECK) Contenedores detenidos correctamente$(NC)"

# Mostrar estado de contenedores
ps:
	@echo "$(YELLOW)$(EMOJI_GEAR) Estado de los contenedores:$(NC)"
	@$(COMPOSE) ps

# Estado detallado del entorno
status:
	@echo "$(BLUE)=====================================$(NC)"
	@echo "$(GREEN)Estado del Entorno CI/CD$(NC)"
	@echo "$(BLUE)=====================================$(NC)"
	@echo "$(YELLOW)Contenedores:$(NC)"
	@$(COMPOSE) ps
	@echo "\n$(YELLOW)Uso de recursos:$(NC)"
	@docker stats --no-stream $(JENKINS_MASTER) $(JENKINS_AGENT) $(WEBSERVER)

# Acceder al shell de Jenkins master
master:
	@echo "$(YELLOW)$(EMOJI_TOOL) Accediendo al shell de Jenkins master...$(NC)"
	@docker exec -it $(JENKINS_MASTER) bash

# Acceder al shell de Jenkins agent
agent:
	@echo "$(YELLOW)$(EMOJI_TOOL) Accediendo al shell de Jenkins agent...$(NC)"
	@docker exec -it $(JENKINS_AGENT) bash

# Acceder al shell del servidor web
web:
	@echo "$(YELLOW)$(EMOJI_TOOL) Accediendo al shell del servidor web...$(NC)"
	@docker exec -it $(WEBSERVER) bash

# Mostrar logs de todos los contenedores
logs:
	@echo "$(YELLOW)$(EMOJI_GEAR) Mostrando logs de los contenedores:$(NC)"
	@$(COMPOSE) logs -f

# Limpiar todos los recursos
clean:
	@echo "$(RED)$(EMOJI_WARN) ¡ADVERTENCIA! Esta acción eliminará todos los contenedores y volúmenes.$(NC)"
	@read -p "¿Estás seguro? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "$(YELLOW)Eliminando todos los recursos...$(NC)"; \
		$(COMPOSE) down -v; \
		echo "$(GREEN)$(EMOJI_CHECK) Recursos eliminados correctamente$(NC)"; \
	fi

# Configurar el agente Jenkins
setup-agent:
	@echo "$(YELLOW)$(EMOJI_GEAR) Copiando script de configuración al agente...$(NC)"
	@docker cp scripts/setup-agent.sh $(JENKINS_AGENT):/tmp/
	@docker exec $(JENKINS_AGENT) chmod +x /tmp/setup-agent.sh
	@echo "$(YELLOW)Ejecutando script de configuración...$(NC)"
	@docker exec $(JENKINS_AGENT) /tmp/setup-agent.sh
	@docker exec $(JENKINS_AGENT) rm /tmp/setup-agent.sh
	@echo "$(GREEN)$(EMOJI_CHECK) Configuración del agente completada$(NC)"

# Configurar el servidor web
setup-webserver:
	@echo "$(YELLOW)$(EMOJI_GEAR) Configurando servidor web...$(NC)"
	@docker cp scripts/setup-webserver.sh $(WEBSERVER):/tmp/
	@docker cp ssh-keys/webserver.pub $(WEBSERVER):/tmp/
	@docker exec $(WEBSERVER) chmod +x /tmp/setup-webserver.sh
	@docker exec $(WEBSERVER) /tmp/setup-webserver.sh
	@docker exec $(WEBSERVER) rm /tmp/setup-webserver.sh
	@docker exec $(WEBSERVER) rm /tmp/webserver.pub
	@echo "$(GREEN)$(EMOJI_CHECK) Configuración del servidor web completada$(NC)"
