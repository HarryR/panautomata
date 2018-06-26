PYTHON ?= python3
NAME = panautomata

PYLINT_IGNORE ?= C0330,invalid-name,line-too-long,missing-docstring,bad-whitespace,consider-using-ternary,wrong-import-position,wrong-import-order,trailing-whitespace


#######################################################################


all:
	@echo "See README.md"

clean:
	rm -rf build dist *.egg-info


#######################################################################
# Distribution

bdist:
	$(PYTHON) setup.py bdist_egg
	$(PYTHON) setup.py bdist_wheel

#######################################################################
# Testing
#

daemon:
	$(PYTHON) -m$(NAME) daemon

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

lint-pyflakes:
	$(PYTHON) -mpyflakes $(NAME)

lint-vulture:
	$(PYTHON) -mvulture $(NAME)

lint-pylint:
	$(PYTHON) -mpylint -d $(PYLINT_IGNORE) $(NAME) || true

lint:lint-pyflakes lint-vulture lint-pylint
