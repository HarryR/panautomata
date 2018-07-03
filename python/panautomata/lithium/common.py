# Copyright (c) 2016-2018 Clearmatics Technologies Ltd
# Copyright (c) 2018 HarryR. All Rights Reserved.
# SPDX-License-Identifier: LGPL-3.0+


from sha3 import keccak_256

from ..ethrpc import EthTransaction
from ..utils import scan_bin, require, u256be
from ..merkle import merkle_tree, merkle_path, merkle_proof


def pack_txn(txn):
    """
    Packs all the information about a transaction into a deterministic fixed-sized array of bytes

        from || to || value || KECCAK256(input)
    """
    tx_from = scan_bin(txn['from'])
    tx_to = scan_bin(txn['to'])
    tx_value = int(txn['value'], 16)
    tx_input = scan_bin(txn['input'])

    # 104 bytes
    result = b''.join([
        tx_from,
        tx_to,
        u256be(tx_value),
        keccak_256(tx_input).digest()
    ])
    assert len(result) == 104
    return result


def pack_log(log):
    """
    Packs a log entry emitted from a contract into a fixed sized number of bytes

        contract-address || event-signature || KECCAK256(event-data)

    It's not possible for transactions and events to be confused.
    Transactions are 104 bytes, logs are 84 bytes

    Indexed parameters are ignored, only the event type and originator contract
    are included along with a hash of the data.

    Event type is a hash of the event signature, e.g. KECCAK256('MyEvent(address,uint256)')
    """
    # 84 bytes
    result = b''.join([
        scan_bin(log['address']),
        scan_bin(log['topics'][0]),
        keccak_256(scan_bin(log['data'])).digest()
    ])
    assert len(result) == 84
    return result


def process_logs(rpc, tx_hash):
    """
    For a given transaction, return the events/logs packed as merkle leafs
    """
    receipt = rpc.eth_getTransactionReceipt(tx_hash)
    items = [pack_log(_) for _ in receipt['logs']]
    log_count = len(receipt['logs'])
    return items, log_count


def process_transaction(rpc, tx_hash):
    transaction = rpc.eth_getTransactionByHash(tx_hash)
    require(transaction is not None, "Transaction is None")
    # Exclude contract creation
    if transaction['to'] is None or transaction['to'] == '0x0':
        return None
    return pack_txn(transaction)


def process_transaction_and_logs(rpc, tx_hash):
    """
    For a given transaction, return the tx and its events/logs as merkle leafs
    """
    transaction = process_transaction(rpc, tx_hash)
    if not transaction:
        return None, 0
    items = [transaction]

    log_items, log_count = process_logs(rpc, tx_hash)
    items += log_items
    return items, log_count


def process_block(rpc, block_height):
    """Returns all items within the block"""
    # TODO: return 'ProcessedBlock' object with items, tx_count and log_count members
    # XXX: given a processed block, we need to be able to easily identify the leaf
    #      for a specific transaction or event within a transaction
    block = rpc.eth_getBlockByNumber(block_height, False)
    if not block['transactions']:
        return [], 0, 0

    log_count = 0
    tx_count = 0
    items = []
    for tx_hash in block['transactions']:
        tx_items, tx_log_count = process_transaction_and_logs(rpc, tx_hash)
        if not tx_items:
            continue
        items += tx_items
        tx_count += 1
        log_count += tx_log_count

    return items, tx_count, log_count


def proof_for_event(rpc, tx_hash, log_idx):
    if isinstance(tx_hash, EthTransaction):
        tx_hash = tx_hash.txid

    # XXX: super messy, very inefficient
    tx_items, tx_log_count = process_transaction_and_logs(rpc, tx_hash)
    require(log_idx < tx_log_count, "Log index beyond log count for transaction")

    transaction = rpc.eth_getTransactionByHash(tx_hash)
    tx_block_height = int(transaction['blockNumber'], 16)

    block_items, block_tx_count, block_log_count = process_block(rpc, tx_block_height)
    tree, root = merkle_tree(block_items)

    # TODO: verify the merkle root matches the on-chain merkle root submitted to LithiumLink

    event_leaf = tx_items[1 + log_idx]
    proof = merkle_path(event_leaf, tree)
    require(merkle_proof(event_leaf, proof, root) is True, "Cannot confirm merkle proof")

    # Proof as accepted by LithiumProver instance
    return u256be(tx_block_height) + b''.join([u256be(_) for _ in proof])


def proof_for_tx(rpc, tx_hash):
    if isinstance(tx_hash, EthTransaction):
        tx_hash = tx_hash.txid

    # XXX: super messy, very inefficient
    tx_leaf = process_transaction(rpc, tx_hash)

    transaction = rpc.eth_getTransactionByHash(tx_hash)
    tx_block_height = int(transaction['blockNumber'], 16)

    block_items, block_tx_count, block_log_count = process_block(rpc, tx_block_height)
    tree, root = merkle_tree(block_items)

    # TODO: verify the merkle root matches the on-chain merkle root submitted to LithiumLink

    proof = merkle_path(tx_leaf, tree)
    require(merkle_proof(tx_leaf, proof, root) is True, "Cannot confirm merkle proof")

    # Proof as accepted by LithiumProver instance
    return tx_leaf, root, u256be(tx_block_height) + b''.join([u256be(_) for _ in proof])
