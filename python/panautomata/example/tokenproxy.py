# Copyright (c) 2018 HarryR. All Rights Reserved.
# SPDX-License-Identifier: GPL-3.0+

from random import randint

from ..utils import require
from ..ethrpc import EthJsonRpc
from ..lithium.common import proof_for_tx, link_wait


LINK_ADDRESS = '0xcfeb869f69431e42cdb54a4f4f105c19c080a601'
PROVER_ADDR = '0xe982e462b094850f12af94d21d470e21be9d0e9c'

LOCK_CONTRACT_ADDR = '0x0290fb167208af455bb137780163b7b7a9a10c16'
TOKEN_CONTRACT_ADDR = '0x9b1f7f645351af3631a656421ed2e40f2802e6c0'

ACCOUNT_ADDR = '0x90f8bf6a479f320ead074411a4b0e7944ea8c9c1'


def main():

    rpc_a = EthJsonRpc('127.0.0.1', 8545)
    link_a = rpc_a.proxy('../solidity/build/contracts/LithiumLink.json', LINK_ADDRESS)
    lock_contract = rpc_a.proxy('../solidity/build/contracts/ExampleCrossTokenLock.json', LOCK_CONTRACT_ADDR, ACCOUNT_ADDR)

    rpc_b = EthJsonRpc('127.0.0.1', 8546)
    link_b = rpc_b.proxy('../solidity/build/contracts/LithiumLink.json', LINK_ADDRESS)
    token_contract = rpc_b.proxy('../solidity/build/contracts/ExampleCrossTokenProxy.json', TOKEN_CONTRACT_ADDR, ACCOUNT_ADDR)

    token_remote = (PROVER_ADDR, 1, TOKEN_CONTRACT_ADDR)
    lock_remote = (PROVER_ADDR, 1, LOCK_CONTRACT_ADDR)

    deposit_value = randint(2 << 10, 2 << 15)
    half_deposit_value = deposit_value // 2

    # make Deposit() with Value on chain A and verify balance
    print("A: Deposit")
    start_balance = rpc_a.eth_getBalance(LOCK_CONTRACT_ADDR)
    deposit_tx = lock_contract.Deposit(token_remote, value=deposit_value)
    deposit_receipt = deposit_tx.wait()
    print(" - deposit receipt:", deposit_receipt)
    deposit_proof = proof_for_tx(rpc_a, deposit_tx)

    after_deposit_balance = rpc_a.eth_getBalance(LOCK_CONTRACT_ADDR)
    require((after_deposit_balance - start_balance) == deposit_value, "Deposit value mismatch")

    # Wait for deposit proof on chain B
    link_wait(link_b, deposit_proof)

    # Perform redemption of tokens equivalent to deposited value
    print("B: Redeem")
    tokens_before_redeem = token_contract.balanceOf(ACCOUNT_ADDR)
    redeem_tx = token_contract.Redeem(lock_remote, token_remote, deposit_value, deposit_proof)
    redeem_receipt = redeem_tx.wait()
    print(" - redeem receipt:", redeem_receipt)
    tokens_after_redeem = token_contract.balanceOf(ACCOUNT_ADDR)
    require((tokens_after_redeem - tokens_before_redeem) == deposit_value)

    # perform Burn() on chain B of half the number of tokens
    print("B: Burn")
    burn_tx = token_contract.Burn(half_deposit_value)
    burn_receipt = burn_tx.wait()
    print(" - burn receipt:", burn_receipt)
    burn_proof = proof_for_tx(rpc_b, burn_tx)
    tokens_after_burn = token_contract.balanceOf(ACCOUNT_ADDR)
    require((tokens_after_redeem - tokens_after_burn) == half_deposit_value)

    # Wait for burn proof on chain A
    link_wait(link_a, burn_proof)

    # on chain A perform Withdraw(), provide proof of Burn
    print("A: Withdraw")
    withdraw_tx = lock_contract.Withdraw(token_remote, half_deposit_value, burn_proof)
    withdraw_receipt = withdraw_tx.wait()
    print(" - withdraw receipt:", withdraw_receipt)
    after_withdraw_balance = rpc_a.eth_getBalance(LOCK_CONTRACT_ADDR)
    require((after_deposit_balance - after_withdraw_balance) == half_deposit_value)


if __name__ == "__main__":
    main()
