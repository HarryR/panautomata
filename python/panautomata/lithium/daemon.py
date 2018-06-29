# Copyright (c) 2016-2018 Clearmatics Technologies Ltd
# Copyright (c) 2018 HarryR. All Rights Reserved.
# SPDX-License-Identifier: LGPL-3.0+

"""
Lithium: Event Relayer between two Ethereum chains

Connects to two RPC endpoints, listens to IonLock events from one chain, packs them, constructs merkle roots and submits them to the IonLink contract of the other chain

This tool was designed to facilitate the information swap between two EVM chains and only works in one direction. To allow two-way communication, two Lithium instances must be initialised.
"""


import time
import threading
from os import urandom

import click
from sha3 import keccak_256

from ..utils import scan_bin, require
from ..args import arg_bytes20, arg_ethrpc
from ..merkle import merkle_tree, merkle_hash

from .api import app


def pack_txn(txn):
    """
    Packs all the information about a transaction into a deterministic fixed-sized array of bytes
        from || to
    """
    fields = [txn['from'], txn['to'], txn['value'], txn['input']]
    encoded_fields = [scan_bin(x + ('0' * (len(x) % 2))) for x in fields]
    tx_from, tx_to, tx_value, tx_input = encoded_fields

    # XXX: why is only the From and To fields... ?
    return b''.join([
        tx_from,
        tx_to,
        tx_value,
        tx_input
    ])


def pack_log(txn, log):
    """
    Packs a log entry into one or more entries.
        sender account || token address of opposite chain from sender || ionLock address of opposite chain from sender || value || hash(reference)
    """
    return b''.join([
        scan_bin(txn['from']),
        scan_bin(txn['to']),
        scan_bin(log['address']),
        scan_bin(log['topics'][1]),
        scan_bin(log['topics'][2]),
        # XXX: why aren't there any extra fields?
    ])


class Lithium(object):
    """
    Lithium process the blocks for the event relat to identify the IonLock transactions which occur
    on the rpc_from chains, which are then added to the IonLink of the rpc_to chain.
    """
    def __init__(self, rpc_from, rpc_to, to_account, link_addr, batch_size):
        assert isinstance(batch_size, int)
        self.checkpoints = {}
        self.leaves = []
        self._run_event = threading.Event()
        self._relay_to = threading.Thread(target=self.lithium_instance)
        self._rpc_from = rpc_from
        self._batch_size = batch_size
        self.contract = rpc_to.proxy("../solidity/build/contracts/LithiumLink.json", link_addr, to_account)

    def process_block(self, block_height):
        """Returns all items within the block"""
        rpc = self._rpc_from
        block = rpc.eth_getBlockByNumber(block_height, False)
        items = []
        log_count = 0
        tx_count = 0
        if block['transactions']:
            for tx_hash in block['transactions']:
                transaction = rpc.eth_getTransactionByHash(tx_hash)

                # Exclude transaction creation?
                if transaction['to'] is None:
                    continue

                tx_count += 1
                items.append(pack_txn(transaction))

                receipt = rpc.eth_getTransactionReceipt(tx_hash)
                if receipt['logs']:
                    for log_entry in receipt['logs']:
                        log_item = pack_log(transaction, log_entry)
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


    def iter_blocks(self, start=1, backlog=0, interval=1):
        """Iterate through the block numbers"""
        rpc = self._rpc_from
        old_head = min(start, max(1, rpc.eth_blockNumber() - backlog))
        print("Starting block height: ", start)
        print("Previous block height: ", old_head)
        blocks = []
        is_latest = False

        # Infinite loop event listener...
        while self._run_event.is_set():
            head = rpc.eth_blockNumber() + 1
            for i in range(old_head, head):
                if i == (head - 1):
                    is_latest = True
                blocks.append(i)
                if is_latest or len(blocks) % self._batch_size == 0:
                    print("Yielded blocks", is_latest, blocks)
                    yield is_latest, blocks
                    blocks = []
                    is_latest = False
            old_head = head
            try:
                time.sleep(interval)
            except KeyboardInterrupt:
                raise StopIteration


    def lithium_submit(self, batch):
        """Submit batch of merkle roots to LithiumLink"""
        print("Submitting batch of", len(batch), "blocks")
        for block_height, block_root in batch:
            print(" -", block_height, block_root)
        transaction = self.contract.Update(batch[0][0] - 1, [_[1] for _ in batch])
        receipt = transaction.wait()
        if int(receipt['status'], 16) == 0:
            raise RuntimeError("Error when submitting blocks! Receipt: " + str(receipt))

        # TODO: wait for transaction
        # TODO: if successful, verify the latest root matches the one we submitted


    def lithium_instance(self):
        batch = []

        latest_block = self.contract.LatestBlock()

        print("Starting block iterator")
        print("Latest Block: ", latest_block)

        for is_latest, block_group in self.iter_blocks(latest_block + 1):
            items, group_tx_count, group_log_count = self.process_block_group(block_group)
            print("blocks %d-%d (%d tx, %d events)" % (min(block_group), max(block_group), group_tx_count, group_log_count))

            for block_height, block_items in items:
                tree, root = merkle_tree(block_items)
                batch.append((block_height, root))

            # Submit when batch size is reached, or item is latest block
            print("Check", is_latest, len(batch), self._batch_size)
            if is_latest or len(batch) >= self._batch_size:
                self.lithium_submit(batch)
                batch = []

        # Submit any remaining items
        if len(batch):
            self.lithium_submit(batch)

    def run(self):
        """ Launches the etheventrelay on a thread"""
        require(False == self._run_event.is_set(), "Already running")
        self._run_event.set()
        self._relay_to.start()

    def stop(self):
        """ Stops the etheventrelay thread """
        require(self._run_event.is_set(), "Not running")
        self._run_event.clear()
        self._relay_to.join()


@click.command(help="Ethereum event merkle tree relay daemon")
@click.option('--rpc-from', callback=arg_ethrpc, metavar="ip:port", default='127.0.0.1:8545', help="Source Ethereum JSON-RPC server")
@click.option('--rpc-to', callback=arg_ethrpc, metavar="ip:port", default='127.0.0.1:8546', help="Destination Ethereum JSON-RPC server")
@click.option('--to-account', callback=arg_bytes20, metavar="0x...20", required=True, help="Recipient")
@click.option('--link', callback=arg_bytes20, metavar="0x...20", required=True, help="IonLink contract address")
@click.option('--api-host', default='127.0.0.1', metavar='addr', help='IP or host')
@click.option('--api-port', type=int, required=True, metavar="N", help="API server endpoint")
@click.option('--batch-size', type=int, default=32, metavar="N", help="Upload at most N items per transaction")
def daemon(rpc_from, rpc_to, to_account, link, api_host, api_port, batch_size):
    lithium = Lithium(rpc_from, rpc_to, to_account, link, batch_size)
    lithium.run()

    app.lithium = lithium

    try:
        app.run(host=api_host, port=api_port)
    except KeyboardInterrupt:
        pass

    lithium.stop()
