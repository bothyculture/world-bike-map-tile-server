.PHONY: build build-no-cache push up down logs logs-f restart clean clean-all status shell shell-db help

# Docker image names
DOCKER_IMAGE=bencollinsuk/world-bike-map-tile-server
DOCKER_IMAGE_DB=bencollinsuk/world-bike-map-tile-server-db

# Default target
.DEFAULT_GOAL := help

## Build Commands
build: ## Build all Docker images
	docker compose build

build-no-cache: ## Build all Docker images without cache
	docker compose build --no-cache

push: build ## Build and push images to registry
	docker push $(DOCKER_IMAGE):latest
	docker push $(DOCKER_IMAGE_DB):latest

## Run Commands
up: ## Start all services in detached mode
	docker compose up -d

up-attached: ## Start all services with logs attached
	docker compose up

down: ## Stop all services
	docker compose down

restart: down up ## Restart all services

## Logging Commands
logs: ## Show logs from all services (last 100 lines)
	docker compose logs --tail=100

logs-f: ## Follow logs from all services
	docker compose logs -f

logs-db: ## Follow logs from database service
	docker compose logs -f db

logs-import: ## Follow logs from import service
	docker compose logs -f import

logs-server: ## Follow logs from server service
	docker compose logs -f server

## Status Commands
status: ## Show status of all services
	docker compose ps

health: ## Check health status of services
	@docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Health}}"

## Shell Access
shell: ## Open shell in server container
	docker compose exec server /bin/bash

shell-db: ## Open shell in database container
	docker compose exec db /bin/bash

psql: ## Connect to PostgreSQL database
	docker compose exec db psql -U renderer -d gis

## Cleanup Commands
clean: ## Stop services and remove containers
	docker compose down --remove-orphans

clean-volumes: ## Stop services and remove containers AND volumes (WARNING: deletes data!)
	docker compose down --volumes --remove-orphans

clean-all: clean ## Remove containers, images, and prune
	docker compose down --rmi local --remove-orphans
	docker image prune -f

## Development Commands
validate: ## Validate docker-compose.yml
	docker compose config --quiet && echo "✓ docker-compose.yml is valid"

secrets-init: ## Initialize secrets directory with default password
	@mkdir -p secrets
	@if [ ! -f secrets/db_password.txt ]; then \
		echo "renderer" > secrets/db_password.txt; \
		chmod 600 secrets/db_password.txt; \
		echo "✓ Created secrets/db_password.txt"; \
	else \
		echo "secrets/db_password.txt already exists"; \
	fi

## Help
help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \\033[36m%-15s\\033[0m %s\\n", $$1, $$2}'
