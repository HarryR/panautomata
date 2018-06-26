ROOT_DIR := $(shell dirname $(realpath $(MAKEFILE_LIST)))

NPM ?= npm
GANACHE ?= $(ROOT_DIR)/node_modules/.bin/ganache-cli
TRUFFLE ?= $(ROOT_DIR)/node_modules/.bin/truffle


all: check-prereqs node_modules lint compile test

clean:
	rm -rf build

dist-clean:
	rm -rf node_modules

check-prereqs:
	@if [ -z "`which $(NPM)`" ]; then \
		echo -e "'npm' not found!\nSee README.md - or install it ('nvm' is good, see https://github.com/creationix/nvm/)"; \
		false; \
	fi

$(TRUFFLE): node_modules

$(GANACHE): node_modules

node_modules:
	$(NPM) install

lint:
	$(NPM) run lint

fedora-dev:
	# use `nvm` to manage nodejs versions, rather than relying on system node
	curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
	nvm install --lts

.PHONY: test
test: $(TRUFFLE)
	$(NPM) run test

testrpc-a: $(TRUFFLE)
	$(NPM) run testrpc-a

testrpc-b: $(TRUFFLE)
	$(NPM) run testrpc-b

deploy-a: $(TRUFFLE)
	$(TRUFFLE) deploy-a --network testrpc-a --reset

deploy-b: $(TRUFFLE)
	$(TRUFFLE) deploy-b --network testrpc-b --reset

compile: $(TRUFFLE)
	$(TRUFFLE) compile

console: $(TRUFFLE)
	$(TRUFFLE) console
