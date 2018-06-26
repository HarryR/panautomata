ROOT_DIR := $(shell dirname $(realpath $(MAKEFILE_LIST)))

NPM ?= npm
GANACHE ?= $(ROOT_DIR)/node_modules/.bin/ganache-cli
TRUFFLE ?= $(ROOT_DIR)/node_modules/.bin/truffle


all: check-prereqs node_modules compile

clean:
	rm -rf build

dist-clean:
	rm -rf node_modules

check-prereqs:
	@if [ -z "`which $(NPM)`" ]; then \
		echo -e "'npm' not found!\nSee README.md - or install it ('nvm' is good, see https://github.com/creationix/nvm/)"; \
		false; \
	fi

node_modules:
	$(NPM) install

lint:
	$(NPM) run lint

fedora-dev:
	# use `nvm` to manage nodejs versions, rather than relying on system node
	curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
	nvm install --lts

test:
	$(NPM) run test

$(TRUFFLE): node_modules

$(GANACHE): node_modules

deploy-a:
	$(TRUFFLE) deploy-a --network testrpc-a --reset

deploy-b:
	$(TRUFFLE) deploy-b --network testrpc-b --reset

compile:
	$(TRUFFLE) compile

console: $(TRUFFLE)
	$(TRUFFLE) console
