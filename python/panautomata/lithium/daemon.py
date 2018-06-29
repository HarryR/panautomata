# Copyright (c) 2016-2018 Clearmatics Technologies Ltd
# Copyright (c) 2018 HarryR. All Rights Reserved.
# SPDX-License-Identifier: LGPL-3.0+

"""
Lithium: Event Relayer between two Ethereum chains

Connects to two RPC endpoints, retrieves transactions and logs from one chain,
packs them, constructs merkle roots and submits them to the IonLink contract of
the other chain.

This tool was designed to facilitate the information swap between two EVM chains
and only works in one direction. To allow two-way communication, two Lithium
instances must be initialised.
"""

import os
import time
import threading

import click
from sha3 import keccak_256

from ..utils import scan_bin, require
from ..args import arg_bytes20, arg_ethrpc
from ..merkle import merkle_tree


def pack_txn(txn):
    """
    Packs all the information about a transaction into a deterministic fixed-sized array of bytes

        from || to || value || KECCAK256(input)
    """
    fields = [txn['from'], txn['to'], txn['value'], txn['input']]
    # NOTE: some fields have an odd number of zeros, e.g. the 'value' field
    encoded_fields = [scan_bin(x + ('0' * (len(x) % 2))) for x in fields]
    tx_from, tx_to, tx_value, tx_input = encoded_fields

    return b''.join([
        tx_from,
        tx_to,
        tx_value,
        keccak_256(tx_input).digest()
    ])


def pack_log(log):
    """
    Packs a log entry emitted from a contract into a fixed sized number of bytes

        contract-address || event-signature || KECCAK256(event-data)

    It's not possible for transactions and events to be confused.
    Transactions are 128 bytes, logs are 96 bytes

    Indexed parameters are ignored, only the event type and originator contract
    are included along with a hash of the data.

    Event type is a hash of the event signature, e.g. KECCAK256('MyEvent(address,uint256)')
    """
    return b''.join([
        scan_bin(log['address']),
        scan_bin(log['topics'][0]),
        keccak_256(scan_bin(log['data'])).digest()
    ])


class Lithium(object):
    """
    Process logs and transactions from the `rpc_from` chain, condensing them into merkle roots
    then relays them to the LithiumLink contract on the `rpc_to` chain.
    """
    def __init__(self, rpc_from, rpc_to, to_account, link_addr, batch_size):
        assert isinstance(batch_size, int)
        self._run_event = threading.Event()
        self._rpc_from = rpc_from
        self._batch_size = batch_size
        # XXX: extract ABI from package resources
        self.contract = rpc_to.proxy("../solidity/build/contracts/LithiumLink.json", link_addr, to_account)

    @property
    def running(self):
        return self._run_event.is_set()

    def process_block(self, block_height):
        """Returns all items within the block"""
        # TODO: return 'ProcessedBlock' object with items, tx_count and log_count members
        rpc = self._rpc_from
        block = rpc.eth_getBlockByNumber(block_height, False)
        if not block['transactions']:
            return [], 0, 0

        log_count = 0
        tx_count = 0
        items = []
        for tx_hash in block['transactions']:
            transaction = rpc.eth_getTransactionByHash(tx_hash)

            # Exclude contract creation
            if transaction['to'] is None:
                continue

            tx_count += 1
            items.append(pack_txn(transaction))

            # Process logs for transaction
            receipt = rpc.eth_getTransactionReceipt(tx_hash)
            if receipt['logs']:
                for log_entry in receipt['logs']:
                    log_item = pack_log(log_entry)
                    items.append(log_item)
                    log_count += 1

        return items, tx_count, log_count

    def process_block_group(self, block_group):
        """
        Process a group of blocks, returning the packed events and transactions
        """
        print("Processing block group")
        items = []
        group_tx_count = 0
        group_log_count = 0
        for block_height in block_group:
            block_items, tx_count, log_count = self.process_block(block_height)
            items.append((block_height, block_items))
            group_tx_count += tx_count
            group_log_count += log_count

        return items, group_tx_count, group_log_count

    def get_block_group(self):
        """
        Retrieve a list of block numbers which need to be synched to the `to` contract
        from the `from` network, in the order that they need to be synched.
        """
        synched_block = self.contract.LatestBlock()
        current_block = self._rpc_from.eth_blockNumber()
        print("Current block:", current_block)
        print("Synched needed:", synched_block)

        # On-chain `to` contract is synched up to the latest `from` block
        if synched_block == current_block:
            return None

        # TODO: simplify expression
        out_blocks = []
        for block_no in range(synched_block + 1, current_block + 1):
            out_blocks.append(block_no)
            if len(out_blocks) == self._batch_size:
                break

        return out_blocks

    def iter_blocks(self, interval=1):
        """
        Iterate through the on-chain block numbers in batches of N starting from `start`
        in the order that they need to be submitted to the on-chain Link contract.
        """
        while self.running:
            try:
                blocks = self.get_block_group()
                if blocks:
                    yield blocks
                time.sleep(interval)
            except KeyboardInterrupt:
                break

    def lithium_submit(self, batch):
        """Submit batch of merkle roots to LithiumLink"""
        print("Submitting batch of", len(batch), "blocks")
        for block_height, block_root in batch:
            print(" -", block_height, block_root)
        transaction = self.contract.Update(batch[0][0] - 1, [_[1] for _ in batch])
        receipt = transaction.wait()
        if int(receipt['status'], 16) == 0:
            raise RuntimeError("Error when submitting blocks! Receipt: " + str(receipt))

        # TODO: if successful, verify the latest root matches the one we submitted

    def run(self):
        """ Launches the etheventrelay on a thread"""
        require(False is self._run_event.is_set(), "Already running")
        self._run_event.set()

        print("Starting block iterator")

        batch = []
        for block_group in self.iter_blocks():
            items, group_tx_count, group_log_count = self.process_block_group(block_group)
            print("blocks %d-%d (%d tx, %d events)" % (min(block_group), max(block_group), group_tx_count, group_log_count))

            for block_height, block_items in items:
                _, root = merkle_tree(block_items)
                batch.append((block_height, root))

            if batch:
                self.lithium_submit(batch)
                batch = []

        # Submit any remaining items
        if batch:
            self.lithium_submit(batch)

    def stop(self):
        """Turn off the 'running' event, causing any loop to exit"""
        self._run_event.clear()


@click.command(help="Ethereum event merkle tree relay daemon")
@click.option('--rpc-from', callback=arg_ethrpc, metavar="ip:port", default='127.0.0.1:8545', help="Source Ethereum JSON-RPC server")
@click.option('--rpc-to', callback=arg_ethrpc, metavar="ip:port", default='127.0.0.1:8546', help="Destination Ethereum JSON-RPC server")
@click.option('--to-account', callback=arg_bytes20, metavar="0x...20", required=True, help="Recipient")
@click.option('--link', callback=arg_bytes20, metavar="0x...20", required=True, help="IonLink contract address")
@click.option('--batch-size', type=int, default=32, metavar="N", help="Upload at most N items per transaction")
@click.option('--pid', metavar="file", help="Save pid to file")
def daemon(rpc_from, rpc_to, to_account, link, batch_size, pid):
    if pid:
        with open(pid, 'w') as handle:
            handle.write(str(os.getpid()))
    lithium = Lithium(rpc_from, rpc_to, to_account, link, batch_size)
    lithium.run()
    print("Stopped")
