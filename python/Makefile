# Copyright (c) 2018 HarryR. All Rights Reserved.
# SPDX-License-Identifier: GPL-3.0+

PYTHON ?= python3
NAME = panautomata

PYLINT_IGNORE ?= C0330,too-many-arguments,invalid-name,line-too-long,missing-docstring,bad-whitespace,consider-using-ternary,wrong-import-position,wrong-import-order,trailing-whitespace
FLAKE8_IGNORE ?= E501


#######################################################################


all: essential-lint test bdist

clean:
	rm -rf build dist *.egg-info .mypy_cache *.pid


#######################################################################
# Distribution

bdist:
	$(PYTHON) setup.py bdist_egg
	$(PYTHON) setup.py bdist_wheel


#######################################################################
# Testing
#

lithium-a2b:
	$(PYTHON) -m$(NAME) lithium --account 0xffcf8fdee72ac11b5c542428b35eef5769c409f0 --rpc-from 127.0.0.1:8545 --rpc-to 127.0.0.1:8546 --contract 0xc89ce4735882c9f0f0fe26686c53074e09b0d550 --pid .lithium.a2b.pid

lithium-b2a:
	$(PYTHON) -m$(NAME) lithium --account 0xffcf8fdee72ac11b5c542428b35eef5769c409f0 --rpc-from 127.0.0.1:8546 --rpc-to 127.0.0.1:8545 --contract 0xc89ce4735882c9f0f0fe26686c53074e09b0d550 --pid .lithium.b2a.pid

lithium-%-stop: .lithium.%.pid
	if [ -f $< ]; then kill -INT `cat $<` || true; fi; rm -f $<;

example-pingpong:
	$(PYTHON) -m$(NAME).example.pingpong

example-swap:
	$(PYTHON) -m$(NAME).example.swap

.PHONY: test
test:
	$(PYTHON) -munittest discover test/


#######################################################################
# Development / Install
#

requirements:
	$(PYTHON) -mpip install -r requirements.txt

requirements-dev:
	$(PYTHON) -mpip install -r requirements-dev.txt


#######################################################################
# Lint
#

# Unused variables, on error - should be fixed.
lint-pyflakes:
	$(PYTHON) -mpyflakes $(NAME)

# Vulture finds unused code
lint-vulture:
	$(PYTHON) -mvulture $(NAME) || true

# Finds TODO: items, lots of useful stuff
lint-pylint:
	$(PYTHON) -mpylint -d $(PYLINT_IGNORE) $(NAME) || true

# Type verification for Python3
# Note: MyPy can't find locally installed Pip packages
lint-mypy:
	MYPYPATH=~/.local/lib/python3.6/site-packages/ $(PYTHON) -mmypy $(NAME) | grep -E "^$(NAME)/" || true

# PEP8 strictness
lint-flake8:
	$(PYTHON) -mflake8 --ignore=$(FLAKE8_IGNORE) $(NAME)

essential-lint: lint-pyflakes lint-flake8

extra-lint: lint-vulture lint-pylint

lint: essential-lint extra-lint 
