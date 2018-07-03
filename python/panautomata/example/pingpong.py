# Copyright (c) 2018 HarryR. All Rights Reserved.
# SPDX-License-Identifier: GPL-3.0+

import os
import time
from random import randint
from binascii import hexlify, unhexlify

from ..crypto import keccak_256
from ..utils import bytes_to_int, u256be
from ..ethrpc import EthJsonRpc
from ..lithium.common import proof_for_tx, proof_for_event


MOCK_PROVER = '0xcfeb869f69431e42cdb54a4f4f105c19c080a601'

LINK_ADDRESS = '0xc89ce4735882c9f0f0fe26686c53074e09b0d550'
REAL_PROVER = '0x0290fb167208af455bb137780163b7b7a9a10c16'

ACCOUNT_A = '0x90f8bf6a479f320ead074411a4b0e7944ea8c9c1'
CONTRACT_A = '0xe982e462b094850f12af94d21d470e21be9d0e9c'

#ACCOUNT_B = '0xffcf8fdee72ac11b5c542428b35eef5769c409f0'
CONTRACT_B = '0x59d3631c86bbe35ef041872d502f218a39fba150'


def link_wait(link_contract, proof):
    block_height = bytes_to_int(proof[:32])
    print("waiting for block height", block_height)
    while True:
        latest_block = link_contract.LatestBlock()
        if latest_block >= block_height:
            break
        print(".", latest_block)
        time.sleep(1)


def main():
    guid = randint(1, 1 << 255)

    rpc_a = EthJsonRpc('127.0.0.1', 8545)
    link_a = rpc_a.proxy('../solidity/build/contracts/LithiumLink.json', LINK_ADDRESS)
    alice = rpc_a.proxy('../solidity/build/contracts/ExamplePingPongA.json', CONTRACT_A, ACCOUNT_A)

    rpc_b = EthJsonRpc('127.0.0.1', 8546)
    link_b = rpc_b.proxy('../solidity/build/contracts/LithiumLink.json', LINK_ADDRESS)
    bob = rpc_b.proxy('../solidity/build/contracts/ExamplePingPongB.json', CONTRACT_B, ACCOUNT_A)

    session_side_alice = (REAL_PROVER, 1, CONTRACT_A)
    session_side_bob = (REAL_PROVER, 1, CONTRACT_B)
    session = (session_side_alice, session_side_bob, 1)

    print("Guid", guid, hexlify(u256be(guid)))

    print("Start")
    tx = alice.Start(guid, session)
    start_receipt = tx.wait()
    start_details = tx.details()
    print("Start Receipt", start_receipt)
    print("Start Receipt Details", start_details)
    start_input = unhexlify(start_details['input'][2:])
    print("Input hashed", hexlify(keccak_256(start_input).digest()))
    start_leaf, start_root, start_proof = proof_for_tx(rpc_a, tx)
    print("Start Leaf", hexlify(start_leaf))
    print("Start Leaf Hash", hexlify(keccak_256(start_leaf).digest()))
    print("Start Root", start_root)
    print("Start Proof", hexlify(start_proof))

    print("ReceiveStart")
    link_wait(link_b, start_proof)
    # TODO: wait until LithiumLink has been relayed the latest block
    tx = bob.ReceiveStart(guid, session, start_proof)
    receive_start_receipt = tx.wait()
    print("Receieve Start Receipt", receive_start_receipt)
    ping_proof = proof_for_event(rpc_b, tx, 0)

    for _ in range(0, 5):
        print("ReceivePing")
        link_wait(link_a, ping_proof)
        # TODO: wait until LithiumLink has been relayed the latest block
        tx = alice.ReceivePing(guid, ping_proof)
        pong_proof = proof_for_event(rpc_a, tx, 0)
        receive_ping_receipt = tx.wait()

        print("ReceivePong")
        link_wait(link_b, pong_proof)
        # TODO: wait until LithiumLink has been relayed the latest block
        tx = bob.ReceivePong(guid, pong_proof)
        ping_proof = proof_for_event(rpc_b, tx, 0)
        receive_pong_receipt = tx.wait()


if __name__ == "__main__":
    main()
