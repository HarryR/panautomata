# Copyright (c) 2016-2018 Clearmatics Technologies Ltd
# Copyright (c) 2018 HarryR. All Rights Reserved.
# SPDX-License-Identifier: LGPL-3.0+

import os

import click

from ..args import arg_bytes20, arg_ethrpc

from .daemon import Lithium


@click.command(help="Ethereum event merkle tree relay daemon")
@click.option('--rpc-from', callback=arg_ethrpc, metavar="ip:port", default='127.0.0.1:8545', help="Source Ethereum JSON-RPC server")
@click.option('--rpc-to', callback=arg_ethrpc, metavar="ip:port", default='127.0.0.1:8546', help="Destination Ethereum JSON-RPC server")
@click.option('--account', callback=arg_bytes20, metavar="0x...20", required=True, help="Recipient")
@click.option('--contract', callback=arg_bytes20, metavar="0x...20", required=True, help="IonLink contract address")
@click.option('--batch-size', type=int, default=32, metavar="N", help="Upload at most N items per transaction")
@click.option('--pid', metavar="file", help="Save pid to file")
def daemon(rpc_from, rpc_to, account, contract, batch_size, pid):
    if pid:
        with open(pid, 'w') as handle:
            handle.write(str(os.getpid()))

    lithium = Lithium(rpc_from, rpc_to, account, contract, batch_size)
    lithium.run()
    print("Stopped")

    if pid:
        os.unlink(pid)
