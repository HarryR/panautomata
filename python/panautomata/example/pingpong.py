# Copyright (c) 2018 HarryR. All Rights Reserved.
# SPDX-License-Identifier: GPL-3.0+

from random import randint
from binascii import hexlify

from ..utils import u256be
from ..ethrpc import EthJsonRpc
from ..lithium.common import proof_for_tx, proof_for_event, link_wait


LINK_ADDRESS = '0xcfeb869f69431e42cdb54a4f4f105c19c080a601'
REAL_PROVER = '0xe982e462b094850f12af94d21d470e21be9d0e9c'

ACCOUNT_A = '0x90f8bf6a479f320ead074411a4b0e7944ea8c9c1'
CONTRACT_A = '0xd833215cbcc3f914bd1c9ece3ee7bf8b14f841bb'

# ACCOUNT_B = '0xffcf8fdee72ac11b5c542428b35eef5769c409f0'
CONTRACT_B = '0x9561c133dd8580860b6b7e504bc5aa500f0f06a7'


def main():

    rpc_a = EthJsonRpc('127.0.0.1', 8545)
    link_a = rpc_a.proxy('../solidity/build/contracts/LithiumLink.json', LINK_ADDRESS)
    alice = rpc_a.proxy('../solidity/build/contracts/ExamplePingPongA.json', CONTRACT_A, ACCOUNT_A)

    rpc_b = EthJsonRpc('127.0.0.1', 8546)
    link_b = rpc_b.proxy('../solidity/build/contracts/LithiumLink.json', LINK_ADDRESS)
    bob = rpc_b.proxy('../solidity/build/contracts/ExamplePingPongB.json', CONTRACT_B, ACCOUNT_A)

    # Parameters for the session
    session_side_alice = (REAL_PROVER, 1, CONTRACT_A)
    session_side_bob = (REAL_PROVER, 1, CONTRACT_B)
    session = (session_side_alice, session_side_bob, 1)

    # Unique ID is chosen for the session
    # This is used, once the session is established, to refer to each side
    guid = randint(1, 1 << 255)
    print("Guid", hexlify(u256be(guid)))

    # Begin session on chain A
    print("Start")
    tx = alice.Start(guid, session)
    start_tx_receipt = tx.wait()
    print("Start TX receipt", start_tx_receipt)
    start_proof = proof_for_tx(rpc_a, tx)
    print("Start proof", hexlify(start_proof))

    # Confirm session on chain B, providing proof of Start
    print("ReceiveStart")
    link_wait(link_b, start_proof)
    tx = bob.ReceiveStart(guid, session, start_proof)
    receive_start_receipt = tx.wait()
    print("ReceiveStart receipt", receive_start_receipt)
    # Starting the session emits a 'Ping' event on chain B
    ping_proof = proof_for_event(rpc_b, tx, 0)
    print("Ping proof", hexlify(ping_proof))

    # Now process the 'ping-pong' events
    # Sends proof of Ping from B to A
    # Then proof of Pong from A to B
    # Repeated ad infinitum
    for _ in range(0, 5):
        # Provide proof of the 'Ping' event
        print("ReceivePing")
        link_wait(link_a, ping_proof)
        tx = alice.ReceivePing(guid, ping_proof)
        receive_ping_receipt = tx.wait()
        print("ReceivePing Receipt", receive_ping_receipt)
        # Which emits a 'Pong' event on chain A
        pong_proof = proof_for_event(rpc_a, tx, 0)
        print("Pong proof", hexlify(pong_proof))

        # Then provide the 'Pong' event proof back to chain B
        print("ReceivePong")
        link_wait(link_b, pong_proof)
        tx = bob.ReceivePong(guid, pong_proof)
        receive_pong_receipt = tx.wait()
        print("ReceivePong receipt", receive_pong_receipt)
        # Which emits a 'Ping' event, going full-circle in a loop
        ping_proof = proof_for_event(rpc_b, tx, 0)
        print("Ping proof", hexlify(ping_proof))


if __name__ == "__main__":
    main()
