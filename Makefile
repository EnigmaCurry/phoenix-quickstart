## Update these default config variables, or override them from environment variables:
## Original public domain template from https://github.com/EnigmaCurry/phoenix-quickstart

## Hint: ?= is like = but it only sets it if its not already set, to make it
## possible to override with an environment variable.

## Choose your application name:
## Must start with a letter and have only lowercase letters, numbers, and underscore
APP ?= phoenix_quickstart
## Release version:
VERSION ?= 0.0.1
## Choose the deployment environment name (dev, prod, etc.):
ENV ?= dev

## Choose your Docker implementation (podman or docker)
DOCKER ?= podman
# DOCKER = docker

## Choose Elixir image version:
## See docker image tags: https://hub.docker.com/_/elixir
ELIXIR_REPO ?= docker.io/elixir
ELIXIR_VERSION ?= 1.13
ELIXIR_IMAGE = "${ELIXIR_REPO}:${ELIXIR_VERSION}"
## Choose Phoenix version:
## See tags: https://github.com/phoenixframework/phoenix/tags
PHOENIX_VERSION ?= v1.6.6
## Choose the version of NodeJS:
## (Phoenix needs webpack/esbuild installed to process static assets)
NODEJS_VERSION ?= 16.x

## Your Docker organizational name:
DOCKER_ORG ?= localhost
## Initial tag for build without any project files:
TAG_INIT ?= ${DOCKER_ORG}/elixir_phoenix:${ELIXIR_VERSION}-${PHOENIX_VERSION}
## Construct full image tag:
## Simple:
# TAG ?= "${DOCKER_ORG}/${APP}:${ENV}-${VERSION}"
## Complex, with full elixir and phoenix version numbers:
TAG ?= "${DOCKER_ORG}/${APP}:${ENV}-${VERSION}-ex-${ELIXIR_VERSION}-phx-${PHOENIX_VERSION}"

## Choose local database container name: (This generic default name allows for multiple
## projects to use the same DB instance within the same named environment)
DATABASE_CONTAINER ?= postgresql-phoenix-${ENV}
## Choose database password:
POSTGRES_PASSWORD ?= postgres
## Choose database username:
POSTGRES_USER ?= postgres
## Database name defaults to the same as the image name:
POSTGRES_DB ?= ${IMAGE}

## HTTP port to serve
HTTP_PORT ?= 4000

RUN_ARGS = --rm -v ${PWD}:/root/src -p ${HTTP_PORT}:4000 --network ${DATABASE_CONTAINER}
BUILD_ARGS = --build-arg=ELIXIR_IMAGE=${ELIXIR_IMAGE} --build-arg=PHOENIX_VERSION=${PHOENIX_VERSION} --build-arg=NODEJS_VERSION=${NODEJS_VERSION}

.PHONY: help # List the Makefile targets and their descriptions
help:
	@echo "Makefile help:"
	@grep '^.PHONY: .* #' Makefile | sed 's/\.PHONY: \(.*\) # \(.*\)/make \1 \t- \2/' | expand -t20

.PHONY: build_initial
build_initial:
	$(eval TMPDIR := $(shell mktemp -d -p .))
	${DOCKER} build -t ${TAG_INIT} ${BUILD_ARGS} --build-arg=APP_DIR=${TMPDIR} . ; rmdir --ignore-fail-on-non-empty ${TMPDIR}

.PHONY: build # Build docker image
build:
	${DOCKER} build -t ${TAG} ${BUILD_ARGS} --build-arg=APP_DIR=. .

.PHONY: init # Initialize new project in current directory
init: network build_initial
	test -d ${APP} || ${DOCKER} run ${RUN_ARGS} ${TAG_INIT} bash -c "mix phx.new ${APP} --live && cd ${APP} && mix deps.get"
	${DOCKER} run -w /root/src/${APP} ${RUN_ARGS} ${TAG_INIT} sed -i "s/hostname: \"localhost\"/hostname: \"${DATABASE_CONTAINER}\"/" config/${ENV}.exs
	@echo "Database hostname written to config/${ENV}.exs"
	${DOCKER} run -w /root/src/${APP} ${RUN_ARGS} ${TAG_INIT} sed -i "s/http: \[ip: {127, 0, 0, 1}, port: 4000\]/http: [ip: {0, 0, 0, 0}, port: 4000]/" config/${ENV}.exs
	@echo "Changed listening IP address to 0.0.0.0 in config/${ENV}.exs"

.PHONY: network
network:
	${DOCKER} network inspect ${DATABASE_CONTAINER} >/dev/null || ${DOCKER} network create ${DATABASE_CONTAINER}
	${DOCKER} network ls | grep ${DATABASE_CONTAINER}

.PHONY: database # Start/Create postgres database container
database: network
	${DOCKER} container inspect ${DATABASE_CONTAINER} >/dev/null || ${DOCKER} run --rm -d --name ${DATABASE_CONTAINER} --network ${DATABASE_CONTAINER} -v ${DATABASE_CONTAINER}:/var/lib/postgresql/data -e POSTGRES_PASSWORD=${POSTGRES_PASSWORD} -e POSTGRES_USER=${POSTGRES_USER} -e POSTGRES_DB=${POSTGRES_DB} docker.io/postgres
	${DOCKER} ps -a | grep ${DATABASE_CONTAINER}
	@echo "Database container started: ${DATABASE_CONTAINER}"
	${DOCKER} run -w /root/src/${APP} ${RUN_ARGS} ${TAG} mix ecto.create

.PHONY: psql # Run `psql` database shell
psql: network
	${DOCKER} exec -it ${DATABASE_CONTAINER} psql ${POSTGRES_DB} ${POSTGRES_USER}

.PHONY: destroy # Destroy all containers and all data
destroy:
	@echo -n "Are you sure you want to destroy the database container and all data? [y/N] " && read ans && if [ $${ans:-'N'} = 'y' ]; then $(MAKE) destroy_db; fi

.PHONY: destroy_db
destroy_db:
	${DOCKER} rm -f -v ${DATABASE_CONTAINER} && echo "Database container removed: ${DATABASE_CONTAINER}"

.PHONY: shell # run BASH shell
shell: network
	${DOCKER} run -it -w /root/src/${APP} ${RUN_ARGS} ${TAG} /bin/bash

.PHONY: serve # Run the service container
serve: network
	${DOCKER} run -it -w /root/src/${APP} ${RUN_ARGS} ${TAG} mix phx.server

.PHONY: all # Run everything necessary to start up from scratch
all: build_initial network init build database serve
