all: solidity python

.PHONY: python
python:
	make -C $@

.PHONY: solidity
solidity:
	make -C $@

%:
	make -C python $@
	make -C solidity $@
