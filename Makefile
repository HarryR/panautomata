all: solidity python

#######################################################################
# Make a specific per-language directory

.PHONY: python
python:
	make -C $@

.PHONY: solidity
solidity:
	make -C $@


#######################################################################
# Perform end-to-end tests which span across projects

end-to-end:
	make -C solidity background-testrpc-a
	make -C solidity deploy-a

	make -C solidity background-testrpc-b
	make -C solidity deploy-b

	make -C python lithium-a2b &
	make -C python lithium-b2a &
	make -C python example-pingpong
	make -C python lithium-a2b-stop
	make -C python lithium-b2a-stop

	make -C solidity stop-testrpc-a
	make -C solidity stop-testrpc-b


#######################################################################
# Everything else gets passed to each project

%:
	make -C solidity $@
	make -C python $@
