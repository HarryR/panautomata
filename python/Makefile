PYTHON ?= python3
NAME = panautomata

PYLINT_IGNORE ?= C0330,invalid-name,line-too-long,missing-docstring,bad-whitespace,consider-using-ternary,wrong-import-position,wrong-import-order,trailing-whitespace
FLAKE8_IGNORE ?= E501

#######################################################################


all: lint-pyflakes test bdist

clean:
	rm -rf build dist *.egg-info .mypy_cache


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
	$(PYTHON) -mvulture $(NAME) || true

lint-pylint:
	$(PYTHON) -mpylint -d $(PYLINT_IGNORE) $(NAME) || true

# XXX: doesn't detect modules!
lint-mypy:
	$(PYTHON) -mmypy $(NAME) || true

lint-flake8:
	$(PYTHON) -mflake8 --ignore=$(FLAKE8_IGNORE) $(NAME) || true

lint: lint-pyflakes lint-vulture lint-pylint lint-flake8
