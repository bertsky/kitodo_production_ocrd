TAGNAME ?= markusweigelt/ocrd_manager
SHELL = /bin/bash

CONTROLLER_ENV_UID ?= $(shell id -u)
CONTROLLER_ENV_GID ?= $(shell id -g)
MANAGER_ENV_UID ?= $(shell id -u)
MANAGER_ENV_GID ?= $(shell id -g)

MODE ?= managed
ifeq (managed,$(MODE))
COMPOSE_FILE = docker-compose.yml:docker-compose.kitodo-app.yml:docker-compose.managed.yml
else
COMPOSE_FILE = docker-compose.yml:docker-compose.kitodo-app.yml
endif
COMPOSE_PATH_SEPARATOR = :

.EXPORT_ALL_VARIABLES:

clean:
	$(RM) -fr kitodo ocrd _modules/kitodo-production-docker/kitodo/build-resources _resources/data

build-keys: ./kitodo/.ssh/id_rsa
build-keys: ./ocrd/manager/.ssh/id_rsa
build-keys: ./ocrd/controller/.ssh/authorized_keys
build-keys: ./ocrd/manager/.ssh/authorized_keys
build-kitodo: | ./_modules/kitodo-production-docker/kitodo/build-resources/
	docker-compose -f ./docker-compose.kitodo-builder.yml up -d --build
build-examples: ./_resources/data

build: build-keys build-kitodo build-examples

./%/:
	mkdir -p $@

./kitodo/.ssh/id_rsa: | ./kitodo/.ssh/
	ssh-keygen -t rsa -q -f $@ -P '' -C 'Kitodo.Production key'

./ocrd/manager/.ssh/id_rsa: | ./ocrd/manager/.ssh/
	ssh-keygen -t rsa -q -f $@ -P '' -C 'OCR-D manager key'

./ocrd/controller/.ssh/authorized_keys: ./ocrd/manager/.ssh/id_rsa | ./ocrd/controller/.ssh/
	cp $<.pub $@

./ocrd/manager/.ssh/authorized_keys: ./kitodo/.ssh/id_rsa
	cp $<.pub $@

./_resources/data: ./_resources/data.zip
	unzip $< -d $@
	touch -m $@

start:
	docker-compose up -d --build

down:
	docker-compose down

stop:
	docker-compose stop

config:
	docker-compose config

status:
	docker-compose ps

define HELP
cat <<"EOF"
Targets:
	- build	create directories and ssh key files
	- start	run docker-compose up
	- down	stop & rm docker-compose up
	- stop	stops docker-compose up
	- config	dump all the composed files
	- status	list running containers

Variables:
	- CONTROLLER_ENV_UID	user id to use on the OCR-D Controller (default: $(CONTROLLER_ENV_UID))
	- CONTROLLER_ENV_GID	group id to use on the OCR-D Controller (default: $(CONTROLLER_ENV_GID))
	- MANAGER_ENV_UID	user id to use on the OCR-D Manager (default: $(MANAGER_ENV_UID))
	- MANAGER_ENV_GID	group id to use on the OCR-D Manager (default: $(MANAGER_ENV_GID))
	- MODE			if 'managed', also starts/stops OCR-D Controller here (default: $(MODE))
EOF
endef
export HELP
help: ; @eval "$$HELP"

.PHONY: clean build build-keys build-kitodo build-examples start down config status help

# do not search for implicit rules here:
%.zip: ;
Makefile: ;
