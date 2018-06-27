all: solidity python

.PHONY: python
python:
	make -C $@

.PHONY: solidity
solidity:
	make -C $@

lint:
	make -C python lint
	make -C solidity lint

clean:
	make -C python clean
	make -C solidity clean
