
class FakeRPC(object):
    def __init__(self, in_blocks, in_transactions, in_receipts):
        self._blocks_by_height = {int(_['number'], 16): _ for _ in in_blocks}
        #self._blocks_by_hash = {_['hash']: _ for _ in in_blocks}
        self._transactions = {_['hash']: _ for _ in in_transactions}
        self._receipts = {_['transactionHash']: _ for _ in in_receipts}

    def eth_getTransactionByHash(self, tx_hash):
        return self._transactions[tx_hash]

    def eth_getTransactionReceipt(self, tx_hash):
        return self._receipts[tx_hash]

    def eth_getBlockByNumber(self, block_height, tx_objects=True):
        assert tx_objects is False  # is only used this way
        return self._blocks_by_height[block_height]
