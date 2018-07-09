import unittest

from binascii import unhexlify, hexlify

from panautomata.utils import bytes_to_int
from panautomata.merkle import merkle_tree
from panautomata.lithium.common import verify_proof, process_block, proof_for_tx, process_transaction

from fakerpc import FakeRPC


FAKERPC_INSTANCE = FakeRPC(
        [   # blocks
            {'number': '0xa',
             'hash': '0x0ecee24d0107cfaa2eb4977d9a9c76e91c955b504820a15130928c180f3d3615',
             'parentHash': '0xb35f11abd3f133da554106422688e84785bd973eaf4ab70d38245ae789711b2c',
             'mixHash': '0x0000000000000000000000000000000000000000000000000000000000000000',
             'nonce': '0x0000000000000000',
             'sha3Uncles': '0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347',
             'logsBloom': '0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
             'transactionsRoot': '0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421',
             'stateRoot': '0x66003709fc92807a818cf2c245b03303f5f1f3640d9cad334c16adb2be27fcec',
             'receiptsRoot': '0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421',
             'miner': '0x0000000000000000000000000000000000000000',
             'difficulty': '0x0',
             'totalDifficulty': '0x0',
             'extraData': '0x',
             'size': '0x3e8',
             'gasLimit': '0xfffffff',
             'gasUsed': '0x2095c',
             'timestamp': '0x5b400a52',
             'transactions': ['0x87f2dd1a154c8f11a153bdcd90fc67ab850e9f32f05a5becc79d3fe035b1c4fd'],
             'uncles': []}
        ],
        [   # transactions
            {'hash': '0x87f2dd1a154c8f11a153bdcd90fc67ab850e9f32f05a5becc79d3fe035b1c4fd',
             'nonce': '0x09',
             'blockHash': '0x0ecee24d0107cfaa2eb4977d9a9c76e91c955b504820a15130928c180f3d3615',
             'blockNumber': '0x0a',
             'transactionIndex': '0x0',
             'from': '0x90f8bf6a479f320ead074411a4b0e7944ea8c9c1',
             'to': '0xd833215cbcc3f914bd1c9ece3ee7bf8b14f841bb',
             'value': '0x0',
             'gas': '0x0dbba0',
             'gasPrice': '0x0ba43b7400',
             'input': '0x79a821d92b7763986e1a1724ddf52242eedd060cdec61fa11fd57c0eea3190653b19773b000000000000000000000000e982e462b094850f12af94d21d470e21be9d0e9c0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000d833215cbcc3f914bd1c9ece3ee7bf8b14f841bb000000000000000000000000e982e462b094850f12af94d21d470e21be9d0e9c00000000000000000000000000000000000000000000000000000000000000010000000000000000000000009561c133dd8580860b6b7e504bc5aa500f0f06a70000000000000000000000000000000000000000000000000000000000000001'}
        ],
        [   # receipts
            {'transactionHash': '0x87f2dd1a154c8f11a153bdcd90fc67ab850e9f32f05a5becc79d3fe035b1c4fd',
             'transactionIndex': '0x0',
             'blockHash': '0x0ecee24d0107cfaa2eb4977d9a9c76e91c955b504820a15130928c180f3d3615',
             'blockNumber': '0xa',
             'gasUsed': '0x2095c',
             'cumulativeGasUsed': '0x2095c',
             'contractAddress': None,
             'logs': [],
             'status': '0x1',
             'logsBloom': '0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'}
        ]
    )


class TestLithiumCommon(unittest.TestCase):
    def test_block(self):
        block, tx_count, log_count = process_block(FAKERPC_INSTANCE, 10)
        self.assertEqual(bytes_to_int(block.items[0]), 21359870359209100823974240316624348723385542012113319844900486161227333295717347719776129330291061)
        self.assertEqual(tx_count, 1)
        self.assertEqual(log_count, 0)

    def test_proof_tx(self):
        block, block_tx_count, block_log_count = process_block(FAKERPC_INSTANCE, 10)
        self.assertEqual(block.hash, '0x0ecee24d0107cfaa2eb4977d9a9c76e91c955b504820a15130928c180f3d3615')

        tx_hash = '0x87f2dd1a154c8f11a153bdcd90fc67ab850e9f32f05a5becc79d3fe035b1c4fd'
        leaf = process_transaction(FAKERPC_INSTANCE, tx_hash)
        self.assertEqual(leaf, b'\x00\x00\x00\x00\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x005\x1c\xae1jW\x1a\xd6\r8\xb8\xf8vf\xd7\x9eG1Kf\xca\xfd\x00\xce\xbc\xa4\xd0\xb6\xf45\xa1u')

        proof = proof_for_tx(FAKERPC_INSTANCE, tx_hash)
        self.assertEqual(len(proof), 48)
        self.assertEqual(proof, b'\x00\x00\x00\x00\x00\x00\x00\n\x00\x00\x00\x00\x00\x00\x00\x00\xe6\x84;\xf3\x93W\x04y\xa2ej\x81\x9b\xf8\xd2\x19\xc1\xdd\xe8\x9f\xe0\xb6\xf7<b\x99\xbf /\xe7U\xd1')

        self.assertEqual(verify_proof(block.root, leaf, proof), True)
