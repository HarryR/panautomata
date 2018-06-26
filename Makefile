all:
	@echo "See README.md"

.PHONY: python
python:
	make -C $@

.PHONY: solidity
solidity:
	make -C $@

lint:
	make -C python lint
	make -C solidity lint
