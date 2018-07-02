# Copyright (c) 2018 HarryR. All Rights Reserved.
# SPDX-License-Identifier: GPL-3.0+

import os
from random import randint

from ..ethrpc import EthJsonRpc

MOCK_PROVER = '0x5b1869d9a4c187f2eaa108f3062412ecf0526b24'

ACCOUNT_A = '0x90f8bf6a479f320ead074411a4b0e7944ea8c9c1'
CONTRACT_A = '0xd833215cbcc3f914bd1c9ece3ee7bf8b14f841bb'

ACCOUNT_B = '0xffcf8fdee72ac11b5c542428b35eef5769c409f0'
CONTRACT_B = '0x9561c133dd8580860b6b7e504bc5aa500f0f06a7'


def main():
    guid = randint(1, 1 << 255)

    rpc_a = EthJsonRpc('127.0.0.1', 8545)
    alice = rpc_a.proxy('../solidity/build/contracts/ExamplePingPongA.json', CONTRACT_A, ACCOUNT_A)

    rpc_b = EthJsonRpc('127.0.0.1', 8546)
    bob = rpc_b.proxy('../solidity/build/contracts/ExamplePingPongB.json', CONTRACT_B, ACCOUNT_B)

    session_side_alice = (MOCK_PROVER, 1, CONTRACT_A)
    session_side_bob = (MOCK_PROVER, 1, CONTRACT_B)
    session = (session_side_alice, session_side_bob, 1)

    print("Start")
    tx = alice.Start(guid, session)
    receipt = tx.wait()
    print(receipt)

    print("ReceiveStart")
    demo_proof = os.urandom(32)
    tx = bob.ReceiveStart(guid, session, demo_proof)
    receipt = tx.wait()
    print(receipt)

    for _ in range(0, 5):
        print("Ping")
        demo_proof = os.urandom(32)
        tx = alice.ReceivePing(guid, demo_proof)
        print(tx.wait())

        print("Pong")
        demo_proof = os.urandom(32)
        tx = bob.ReceivePong(guid, demo_proof)
        print(tx.wait())


if __name__ == "__main__":
    main()
