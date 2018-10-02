current_dir := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf ($$1 ~ "--" ? $$2 "\n" : "\033[36m%-10s \033[34m%s\033[0m\n", $$1,  $$2)}'
.DEFAULT_GOAL := help

########################################################################################################################
####                                            SET ENVIRONMENT VARIABLES                                           ####
########################################################################################################################
export MY_UID ?=$(shell id -u)
export MY_GID ?=$(shell id -g)
export REGISTRY ?=project
export DOMAIN ?=alterway.devs
export PROJECT_ROOT ?= $(shell pwd)

export SITE_NAME ?=Project Service Core
export PROJECT_BUILD ?= local
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

SWARM_MODE = $(shell docker info -f {{.Swarm.LocalNodeState}} 2>&-)
ifeq ($(shell [ ${SWARM_MODE} = "active" -a -z ${NO_SWARM} ] && echo "true"), true)
	export DEPLOY_MODE ?= swarm
	export NETWORK_DRIVER ?= overlay
else
	export DEPLOY_MODE ?= docker-compose
	export NETWORK_DRIVER ?= bridge
	ifndef SWARM_MODE
		SWARM_MODE = n/a
	endif
endif
export SUFFIX_VS ?=${DEPLOY_MODE}

export MOD_VERBOSE ?=1
ifeq (${MOD_VERBOSE},0)
	export OUTPUT := 2>/dev/null 1>/dev/null
endif

export MOD_DEV ?=0
ifeq (${MOD_DEV},1)
	export DOCKER_COMPOSE_SUFFIX := -dev
endif

export LOCALIP ?=$(shell ip addr show | awk '$$1 == "inet" && $$3 == "brd" { sub (/\/.*/,""); print $$2 }' | head -n1)

export RELEASE_FILES ?="Resources/doc/index.md"
export RELEASE_REMOTE ?=origin

export CI_BUILD_REF_CUT=${CI_BUILD_REF:0:8}
export CI_COMMIT_REF_NAME ?=develop

########################################################################################################################
####                                                    OVERLOAD                                                    ####
########################################################################################################################
include ${current_dir}/Makefile-${SUFFIX_VS}

########################################################################################################################
####                                                      STACK                                                     ####
########################################################################################################################

#   make tag RELEASE_VERSION=(major|minor|patch) RELEASE_FILES="Resources/doc/index.md"
tag: ## Publish new release. Usage: (You need to install https://github.com/flazz/semver/ before)
tag:
	@semver inc $(RELEASE_VERSION)
	@echo "New release: `semver tag`"
	@echo Releasing sources
	@(sed -i -r "s/(v[0-9]+\.[0-9]+\.[0-9]+)/`semver tag`/g" $(RELEASE_FILES)) || true

#   make release
release: ## Tag git with last release
release:
	@(git add .) || true
	@(git commit --no-verify -m "#000 releasing `semver tag`") || true
	@(git tag --delete `semver tag`) || true
	@(git push --no-verify --delete ${RELEASE_REMOTE} `semver tag`) || true
	@git tag `semver tag`
	@git push --no-verify ${RELEASE_REMOTE} `semver tag`
	@GIT_CB=$(git symbolic-ref --short HEAD) && git push --no-verify -u ${RELEASE_REMOTE} $(GIT_CB)

changelog: ## Create CHANGELOG file
changelog:
	@echo " ${PROJECT_NAME} project ($(RELEASE_VERSION)) unstable; urgency=low" >/tmp/changelog
	@echo >> CHANGELOG.md
	@git log $(CURRENT_TAG)...HEAD --pretty=format:'   * %s ' --reverse >> /tmp/changelog
	@echo >> /tmp/changelog
	@echo >> /tmp/changelog
	@echo  "  -- Etienne de Longeaux <sfynx@pi-groupe.net>  $(shell date --rfc-2822)" >> /tmp/changelog
	@echo >> /tmp/changelog
	@# prepend to changelog
	@cat /tmp/changelog|cat - CHANGELOG.md > /tmp/out && mv /tmp/out CHANGELOG.md
	@echo >> CHANGELOG.md

# make job-changelog GIT_OPTIONS="--github-site=https://git.alterway.fr -u alidade -p alidade-ui"
# options: https://github.com/github-changelog-generator/github-changelog-generator/wiki/Advanced-change-log-generation-examples
job-changelog: ## Generate changelog from github repository
job-changelog:
	@docker run -it --rm -v "$(pwd)":/usr/local/src/your-app ferrarimarco/github-changelog-generator $$GIT_OPTIONS

# make job-changelog-2 GIT_OPTIONS="--user=pigroupe,--repository=SfynxCoreBundle,--milestone=2.8.3"
# options: https://github.com/jwage/changelog-generator
job-changelog-2: ## Generate changelog from github repository
job-changelog-2:
	@${docker-tools} run --rm php-cmd phing -f build.xml git:changelog -Dgit.options=$$GIT_OPTION >> CHANGELOG.md
