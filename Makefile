COMPOSE = docker compose -f srcs/docker-compose.yml
DATA    = $(HOME)/data

all: up

up:
	@mkdir -p $(DATA)/mariadb $(DATA)/wordpress
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

clean:
	$(COMPOSE) down -v

fclean: clean
	$(COMPOSE) down --rmi all 2>/dev/null || true
	@sudo rm -rf $(DATA)/mariadb $(DATA)/wordpress

re: fclean up

.PHONY: all up down clean fclean re
