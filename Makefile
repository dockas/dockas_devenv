comma := ,
space :=  

all: up

.PHONY: up destroy ps machine

machine:
	$(eval status := $(shell docker-machine status dockas-1))

	@if [ "$(status)" = "Stopped" ]; then \
		echo ">> starting dockas-1 machine"; \
		docker-machine start dockas-1; \
	elif [ "$(status)" = "Running" ]; then \
		echo ">> dockas-1 machine already running"; \
	else \
		echo ">> creating dockas-1 machine"; \
		docker-machine create -d virtualbox dockas-1; \
	fi

	$(eval ip := $(shell docker-machine ip dockas-1))
	$(eval bip := $(shell docker-machine ssh dockas-1 ifconfig docker0 | grep 'inet addr:' | awk '{print $$2}' | sed 's/addr://g'))

	@if [ ! -f docker-compose.yml ]; then \
		echo ">> generating docker-compose.yml file"; \
		sed 's/192.168.99.100/'"$(ip)"'/g; s/172.17.0.1/'"$(bip)"'/g' docker-compose.yml.tpl > docker-compose.yml; \
	else \
		echo ">> docker-compose.yml already exists"; \
	fi

ps:
	@eval $$(docker-machine env dockas-1); \
	docker ps

logs:
	@eval $$(docker-machine env dockas-1); \
	docker-compose logs -f $(srv)

restart:
	@eval $$(docker-machine env dockas-1); \
	docker-compose restart $(srv)

scale:
	@eval $$(docker-machine env dockas-1); \
	docker-compose scale $(srv)=$(num)

up: machine
	@eval $$(docker-machine env dockas-1); \
	docker-compose up -d consul registrator && \
	sleep 10 && \
	docker-compose up -d mongo redis && \
	sleep 10 && \
	docker-compose up -d api_rest && \
	sleep 10 && \
	docker-compose up -d webapp && \
	sleep 10 && \
	docker-compose up -d nginx

update:
	git submodule foreach git pull origin master

destroy:
	@eval $$(docker-machine env dockas-1); \
	docker-compose stop; \
	docker-compose rm -f;

rmi: destroy
	@eval $$(docker-machine env dockas-1); \
	docker rmi $(addprefix dockasdevenv_, $(shell echo $(srv) | sed -E 's/,/ /g'))

rmi_srv:
	make rmi srv=api_rest

build:
	@eval $$(docker-machine env dockas-1); \
	docker-compose build $(shell echo $(srv) | sed -E 's/,/ /g')

build_srv:
	@eval $$(docker-machine env dockas-1); \
	docker-compose build api_rest

rmv:
	@eval $$(docker-machine env dockas-1); \
	docker volume rm $$(docker volume ls -q -f dangling=true)
