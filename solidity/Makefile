# Copyright (c) 2018 HarryR. All Rights Reserved.
# SPDX-License-Identifier: GPL-3.0+

ROOT_DIR := $(shell dirname $(realpath $(MAKEFILE_LIST)))

NPM ?= npm
GANACHE ?= $(ROOT_DIR)/node_modules/.bin/ganache-cli
TRUFFLE ?= $(ROOT_DIR)/node_modules/.bin/truffle

ABI_CONTRACTS = ExampleSwap LithiumLink LithiumProver ExampleERC20Token
ABI_FILES = $(addsuffix .abi,$(addprefix abi/,$(ABI_CONTRACTS)))


all: check-prereqs node_modules lint compile abi test

.PHONY: abi
abi: $(ABI_FILES)

clean:
	rm -rf build

dist-clean:
	rm -rf node_modules

check-prereqs:
	@if [ -z "`which $(NPM)`" ]; then \
		echo -e "'npm' not found!\nSee README.md - or install it ('nvm' is good, see https://github.com/creationix/nvm/)"; \
		false; \
	fi


abi/%.abi: build/contracts/%.json
	$(PYTHON) ./utils/extract-abi.py $< > $@


$(TRUFFLE): node_modules

$(GANACHE): node_modules

node_modules:

.PHONY: npm-install
npm-install:
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
	$(TRUFFLE) deploy-a --network testrpc_a --reset

deploy-b: $(TRUFFLE)
	$(TRUFFLE) deploy-b --network testrpc_b --reset

compile: $(TRUFFLE)
	$(TRUFFLE) compile

console: $(TRUFFLE)
	$(TRUFFLE) console
