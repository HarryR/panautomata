# Copyright (c) 2018 HarryR. All Rights Reserved.
# SPDX-License-Identifier: GPL-3.0+

PYTHON ?= python3
NAME = panautomata

PYLINT_IGNORE ?= C0330,too-many-arguments,invalid-name,line-too-long,missing-docstring,bad-whitespace,consider-using-ternary,wrong-import-position,wrong-import-order,trailing-whitespace
FLAKE8_IGNORE ?= E501


LITHIUM_A2B_ARGS = --account 0xffcf8fdee72ac11b5c542428b35eef5769c409f0 --rpc-from 127.0.0.1:8545 --rpc-to 127.0.0.1:8546 --contract 0xcfeb869f69431e42cdb54a4f4f105c19c080a601 --pid .lithium.a2b.pid
LITHIUM_B2A_ARGS = --account 0xffcf8fdee72ac11b5c542428b35eef5769c409f0 --rpc-from 127.0.0.1:8546 --rpc-to 127.0.0.1:8545 --contract 0xcfeb869f69431e42cdb54a4f4f105c19c080a601 --pid .lithium.b2a.pid


COVERAGE=$(PYTHON) -mcoverage run --source=$(NAME) -p


#######################################################################


all: essential-lint test bdist

clean:
	rm -rf build dist *.egg-info .mypy_cache *.pid htmlcov .coverage


#######################################################################
# Distribution

bdist: bdist-wheel

bdist-wheel:
	$(PYTHON) setup.py bdist_wheel

bdist-egg:
	$(PYTHON) setup.py bdist_egg


#######################################################################
# Testing
#

lithium-a2b:
	$(COVERAGE) -m $(NAME) lithium $(LITHIUM_A2B_ARGS)

lithium-b2a:
	$(COVERAGE) -m $(NAME) lithium $(LITHIUM_B2A_ARGS)

lithium-%-stop: .lithium.%.pid
	if [ -f $< ]; then kill -INT `cat $<` || true; fi; rm -f $<;

example-tokenproxy:
	$(COVERAGE) -m $(NAME).example.tokenproxy

example-pingpong:
	$(COVERAGE) -m $(NAME).example.pingpong

example-swap:
	$(COVERAGE) -m $(NAME).example.swap

.PHONY: test
test:
	$(COVERAGE) -m unittest discover test/


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

coverage-combine:
	$(PYTHON) -mcoverage combine

coverage-report:
	$(PYTHON) -mcoverage report

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
