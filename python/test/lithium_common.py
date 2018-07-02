#!/usr/bin/env python3

from panautomata.ethrpc import EthJsonRpc
from panautomata.lithium.common import *


def main():
    rpc = EthJsonRpc('127.0.0.1', 8545)
    proof = proof_for_event(rpc, '0x8c0ae35d1fd97eda382ed63035976ebda1ad305046ab9716d1a78e8a94d55bcb', 0)
    print(proof)


if __name__ == "__main__":
    main()
