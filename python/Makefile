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

test-daemon:
	$(PYTHON) -m$(NAME) daemon --to-account 0xffcf8fdee72ac11b5c542428b35eef5769c409f0 --rpc-from 127.0.0.1:8545 --rpc-to 127.0.0.1:8546 --link 0xcfeb869f69431e42cdb54a4f4f105c19c080a601 --pid .daemon.pid

test-daemon-stop:
	if [ -f .daemon.pid ]; then kill -INT `cat .daemon.pid` && rm -f .daemon.pid; fi

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
	MYPYPATH=~/.local/lib/python3.6/site-packages/ $(PYTHON) -mmypy $(NAME) | grep -E "^$(NAME)/" || true

lint-flake8:
	$(PYTHON) -mflake8 --ignore=$(FLAKE8_IGNORE) $(NAME) || true

lint: lint-pyflakes lint-vulture lint-pylint lint-flake8
