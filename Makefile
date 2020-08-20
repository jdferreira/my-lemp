DOCKER_COMPOSE_DIR = .docker
DOCKER_COMPOSE_FILE = $(DOCKER_COMPOSE_DIR)/docker-compose.yml
DOCKER_COMPOSE = docker-compose -f $(DOCKER_COMPOSE_FILE) --project-directory $(DOCKER_COMPOSE_DIR)
WORKSPACE_CONTAINER = workspace
DB_CONTAINER = db
DEFAULT_GOAL = help

help:
	@awk 'BEGIN { FS = ":.*##"; printf "\n\033[1mUsage\033[0m:\n  make \033[36m<target>\033[0m\n"; } /^##@/ { printf "\n\033[1m%s\033[0m:\n", substr($$0, 5); } /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%s\033[0m %s\n", $$1, $$2; }' $(MAKEFILE_LIST)

##@ Docker Infrastructure for this project

$(DOCKER_COMPOSE_DIR)/.env:
	cp $(DOCKER_COMPOSE_DIR)/.env.example $(DOCKER_COMPOSE_DIR)/.env
	sed -i \
		-e 's/__UID__/'"$$(id -u)"'/' \
		-e 's/__GID__/'"$$(getent group $$(groups | cut -d' ' -f1) | cut -d':' -f3)"'/' \
		$(DOCKER_COMPOSE_DIR)/.env
	awk \
		-v rng="tr -dc '[:alpha:][:digit:]/+_@!' </dev/urandom | fold -w 16" \
		'/__PASSWORD__/ { rng | getline r; gsub("__PASSWORD__", r); } /.*/' \
		$(DOCKER_COMPOSE_DIR)/.env > /tmp/env && mv /tmp/env $(DOCKER_COMPOSE_DIR)/.env

$(DOCKER_COMPOSE_DIR)/workspace/.ssh/id_rsa:
	ssh-keygen -t rsa -b 4096 -f $(DOCKER_COMPOSE_DIR)/workspace/.ssh/id_rsa -N "$$(grep SSH_PASSPHRASE $(DOCKER_COMPOSE_DIR)/.env | sed -E 's/SSH_PASSPHRASE\s*=\s*//')"

.PHONY: docker-init
docker-init: $(DOCKER_COMPOSE_DIR)/.env $(DOCKER_COMPOSE_DIR)/workspace/.ssh/id_rsa ## Ensure the .env file exists and replace environment-specific variables.
	mkdir -p $(DOCKER_COMPOSE_DIR)/db/data

.PHONY: docker-build
docker-build: docker-init ## Build all containers. To build a specific container, use CONTAINER=<service>
	$(DOCKER_COMPOSE) build --parallel $(CONTAINER) && \
	$(DOCKER_COMPOSE) up -d --force-recreate $(CONTAINER)

.PHONY: docker-build-from-scratch
docker-build-from-scratch: docker-init ## Build all containers from scratch, without cache etc. To build a specific container, use CONTAINER=<service>
	$(DOCKER_COMPOSE) rm -fs $(CONTAINER) && \
	$(DOCKER_COMPOSE) build --parallel --pull --no-cache $(CONTAINER) && \
	$(DOCKER_COMPOSE) up -d --force-recreate $(CONTAINER)

.PHONY: docker-up
docker-up: docker-init ## Start all docker containers. To start only one container, use CONTAINER=<service>
	$(DOCKER_COMPOSE) up -d $(CONTAINER)

.PHONY: docker-test
docker-test: ## Run the infrastructure tests for the docker setup.
	@bash $(DOCKER_COMPOSE_DIR)/docker-test.sh

.PHONY: docker-enter
docker-enter: ## Drop into a shell inside the container specified with CONTAINER=<service>
#	The next line ensures that if we did not specify a container, we drop into the default workspace container
	$(eval CONTAINER ?= $(WORKSPACE_CONTAINER))
	$(DOCKER_COMPOSE) exec $(CONTAINER) bash

.PHONY: docker-ps
docker-ps: ## Show the running containers
	$(DOCKER_COMPOSE) ps

.PHONY: docker-logs
docker-logs: docker-up ## Show the logs for the containers. You can define a FLAGS=<flags> variable to pass to the logs (such as -f, for example). You can also specify the container you are interested in with CONTAINER=<service>
	$(DOCKER_COMPOSE) logs $(FLAGS) $(CONTAINER)

.PHONY: docker-down
docker-down: docker-init ## Stop all docker containers.
	$(DOCKER_COMPOSE) down

.PHONY: docker-clean
docker-clean: ## Remove the .env file and the local database volume.
	$(DOCKER_COMPOSE) exec $(DB_CONTAINER) bash -c 'rm -rf /var/lib/mysql/*' || sudo rm -rf $(DOCKER_COMPOSE_DIR)/db/data
	rm -f $(DOCKER_COMPOSE_DIR)/.env
	rm -f $(DOCKER_COMPOSE_DIR)/workspace/.ssh/id_rsa{,.pub}
	mkdir -p $(DOCKER_COMPOSE_DIR)/db/data
