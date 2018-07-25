DEFAULT_GOAL := help

########################################################################################################################
####                                            SET ENVIRONMENT VARIABLES                                           ####
########################################################################################################################
export MY_UID ?=$(shell id -u)
export MY_GID ?=$(shell id -g)
export REGISTRY ?=project
export DOMAIN ?=alterway.devs
export PROJECT_ROOT ?= $(shell pwd)

export SITE_NAME ?=Project Service Core
export PROJECT_NAME ?=project
export SERVICE_NAME ?=project
export PHP_INIT_SERVICES ?=php
export UPDATE_SERVICES ?=
export INFRA_ENV ?=project-local
export PHP_NAME ?=cmd
export PHP_ENV ?=php.env
export ENV_NAME ?=.env
export ANALYSE_PATH ?=src
export ANALYSE_PROJET_ENV ?=${SERVICE_NAME}
export VOLUMES_SHARED ?=documentation data/build data/documentation data/cache data/log
export OPTIONS_COMP ?=--no-dev

export DOCKER_BINARY := $(shell which docker)
export DOCKER_VERSION := $(shell docker --version | awk {'print $$3'} | sed 's/[^0-9]//g')
export DOCKER_COMPOSE_VERSION := $(shell docker-compose -v | awk {'print $$3'} | sed 's/[^0-9]//g')
export DOCKER_VERSION_CP := $(shell [ ${DOCKER_VERSION} -ge 1705 ] && echo true)

export DOCKER_COMPOSE_VERSION_CP_V2 := $(shell [ ${DOCKER_COMPOSE_VERSION} -ge 170 ] && [ ${DOCKER_COMPOSE_VERSION} -lt 1161 ] && echo true)
export DOCKER_COMPOSE_VERSION_CP_V3 := $(shell [ ${DOCKER_COMPOSE_VERSION} -ge 1161 ] && echo true)
DEPLOY_VERSION=
ifeq (${DOCKER_COMPOSE_VERSION_CP_V2}, true)
	export DEPLOY_VERSION=v2
endif
ifeq (${DOCKER_COMPOSE_VERSION_CP_V3}, true)
	ifeq (${DOCKER_VERSION_CP}, true)
	    export DEPLOY_VERSION=v3
	endif
endif
export SUFFIX_VS ?=${DEPLOY_VERSION}

export MOD_VERBOSE ?=1
ifeq (${MOD_VERBOSE},0)
	export OUTPUT := 2>/dev/null 1>/dev/null
endif

export MOD_DEV ?=0
ifeq (${MOD_DEV},1)
	export DOCKER_COMPOSE_SUFFIX := -dev
endif

export CI_BUILD_REF_CUT=${CI_BUILD_REF:0:8}
export LOCALIP ?=$(shell ip addr show | awk '$$1 == "inet" && $$3 == "brd" { sub (/\/.*/,""); print $$2 }' | head -n1)

########################################################################################################################
####                                                      STACK                                                     ####
########################################################################################################################

%:
	@$(MAKE) -B -f config/makefile/Makefile-$$SUFFIX_VS $@
