# Copyright (c) 2016-2018 Clearmatics Technologies Ltd
# Copyright (c) 2018 HarryR. All Rights Reserved.
# SPDX-License-Identifier: LGPL-3.0+

import time
from collections import namedtuple
from binascii import unhexlify

from ..crypto import keccak_256
from ..ethrpc import EthTransaction
from ..utils import scan_bin, require, u256be, u64be, u32be, bytes_to_int
from ..merkle import merkle_tree, merkle_path, merkle_proof


Block = namedtuple('Block', ('height', 'root', 'hash', 'items'))


def leaf_prefix(txn_or_log, log_idx=None):
    """
    Prefix for merkle leaves, which binds them to a specific log, transaction at
    a block height.
    """
    if log_idx is None:
        log_idx = int(txn_or_log.get('logIndex', '0x0'), 16)
    assert isinstance(log_idx, int)

    block_hash = unhexlify(txn_or_log['blockHash'][2:])
    tx_index = int(txn_or_log['transactionIndex'], 16)

    result = block_hash + u32be(tx_index) + u32be(log_idx)
    require(len(result) == (32 + 4 + 4))

    return result


def proof_prefix(txn_or_log, log_idx=None):
    """
    Prefix for merkle leaves, which binds them to a specific log, transaction at
    a block height.
    """
    if log_idx is None:
        log_idx = int(txn_or_log.get('logIndex', '0x0'), 16)
    assert isinstance(log_idx, int)

    block_height = int(txn_or_log['blockNumber'], 16)
    tx_index = int(txn_or_log['transactionIndex'], 16)

    result = u64be(block_height) + u32be(tx_index) + u32be(log_idx)
    require(len(result) == 16)

    return result


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
    inner_leaf = b''.join([
        tx_from,
        tx_to,
        u256be(tx_value),
        keccak_256(tx_input).digest()
    ])
    require(len(inner_leaf) == 104)

    outer_leaf = leaf_prefix(txn) + keccak_256(inner_leaf).digest()
    require(len(outer_leaf) == 32 + 40)

    return outer_leaf


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
    inner_leaf = b''.join([
        scan_bin(log['address']),
        scan_bin(log['topics'][0]),
        keccak_256(scan_bin(log['data'])).digest()
    ])
    require(len(inner_leaf) == 84)

    outer_leaf = leaf_prefix(log) + keccak_256(inner_leaf).digest()
    require(len(outer_leaf) == 32 + 40)

    return outer_leaf


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
    # print("Log items Hashed", [hexlify(keccak_256(_).digest()) for _ in log_items])
    # print("Log items Unhashed", [hexlify(_) for _ in log_items])
    items += log_items
    return items, log_count


def process_block(rpc, block_height):
    """Returns all items within the block"""
    block = rpc.eth_getBlockByNumber(block_height, False)

    log_count = 0
    tx_count = 0
    items = []

    for tx_hash in block['transactions']:
        tx_items, tx_log_count = process_transaction_and_logs(rpc, tx_hash)
        if not tx_items:
            # Some transactions result in no leaves, e.g. contract creation
            continue
        items += tx_items
        tx_count += 1
        log_count += tx_log_count

    _, merkle_root = merkle_tree(items)

    block_hash = bytes_to_int(unhexlify(block['hash'][2:]))

    return Block(block_height, merkle_root, block_hash, items), tx_count, log_count


def proof_for_event(rpc, tx_hash, log_idx):
    if isinstance(tx_hash, EthTransaction):
        tx_hash = tx_hash.txid

    # XXX: super messy, very inefficient
    tx_items, tx_log_count = process_transaction_and_logs(rpc, tx_hash)
    require(log_idx < tx_log_count, "Log index beyond log count for transaction")

    transaction = rpc.eth_getTransactionByHash(tx_hash)
    tx_block_height = int(transaction['blockNumber'], 16)

    block, tx_count, tx_log_count = process_block(rpc, tx_block_height)

    tree, root = merkle_tree(block.items)

    # TODO: verify the merkle root matches the on-chain merkle root submitted to LithiumLink

    event_leaf = tx_items[1 + log_idx]
    proof = merkle_path(event_leaf, tree)
    require(merkle_proof(event_leaf, proof, block.root) is True, "Cannot confirm merkle proof")

    # Proof as accepted by LithiumProver instance
    prefix = proof_prefix(transaction, log_idx)
    return prefix + b''.join([u256be(_) for _ in proof])


def proof_for_tx(rpc, tx_hash):
    if isinstance(tx_hash, EthTransaction):
        tx_hash = tx_hash.txid

    # XXX: super messy, very inefficient
    tx_leaf = process_transaction(rpc, tx_hash)

    transaction = rpc.eth_getTransactionByHash(tx_hash)
    tx_block_height = int(transaction['blockNumber'], 16)

    block, tx_count, tx_log_count = process_block(rpc, tx_block_height)

    tree, root = merkle_tree(block.items)

    # TODO: verify the merkle root matches the on-chain merkle root submitted to LithiumLink

    proof = merkle_path(tx_leaf, tree)
    require(merkle_proof(tx_leaf, proof, block.root) is True, "Cannot confirm merkle proof")

    # Proof as accepted by LithiumProver instance
    prefix = proof_prefix(transaction)
    return prefix + b''.join([u256be(_) for _ in proof])


def verify_proof(root, leaf, proof):
    # Prefix is 16 bytes
    require((len(proof) - 16) % 32 == 0)
    require((len(proof) - 16) >= 32)
    proof = proof[16:]
    path = []
    while proof:
        path.append(bytes_to_int(proof[:32]))
        proof = proof[32:]

    return merkle_proof(leaf, path, root)


def link_wait(link_contract, proof, interval=1):
    """
    Wait for the LithiumLink contract to reach the height required
    to validate the proof.
    """
    block_height = bytes_to_int(proof[:8])
    while True:
        latest_block = link_contract.GetHeight()
        if latest_block >= block_height:
            break
        time.sleep(interval)
        print("Waiting for block", block_height)
