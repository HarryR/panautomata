# Copyright (c) 2018 HarryR. All Rights Reserved.
# SPDX-License-Identifier: GPL-3.0+

PYTHON ?= python3
NAME = panautomata

PYLINT_IGNORE ?= C0330,invalid-name,line-too-long,missing-docstring,bad-whitespace,consider-using-ternary,wrong-import-position,wrong-import-order,trailing-whitespace
FLAKE8_IGNORE ?= E501

#######################################################################


all: lint-pyflakes test bdist

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

test-daemon-a2b:
	$(PYTHON) -m$(NAME) daemon --to-account 0xffcf8fdee72ac11b5c542428b35eef5769c409f0 --rpc-from 127.0.0.1:8545 --rpc-to 127.0.0.1:8546 --link 0xcfeb869f69431e42cdb54a4f4f105c19c080a601 --pid .daemon.a2b.pid

test-daemon-b2a:
	$(PYTHON) -m$(NAME) daemon --to-account 0xffcf8fdee72ac11b5c542428b35eef5769c409f0 --rpc-from 127.0.0.1:8546 --rpc-to 127.0.0.1:8545 --link 0xcfeb869f69431e42cdb54a4f4f105c19c080a601 --pid .daemon.b2a.pid

test-daemon-%-stop: .daemon.%.pid
	if [ -f $< ]; then kill -INT `cat $<` || true; fi; rm -f $<;

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
lint-mypy:
	MYPYPATH=~/.local/lib/python3.6/site-packages/ $(PYTHON) -mmypy $(NAME) | grep -E "^$(NAME)/" || true

# PEP8 strictness
lint-flake8:
	$(PYTHON) -mflake8 --ignore=$(FLAKE8_IGNORE) $(NAME) || true

lint: lint-pyflakes lint-vulture lint-pylint lint-flake8
