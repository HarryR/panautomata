# Copyright (c) 2018 HarryR. All Rights Reserved.
# SPDX-License-Identifier: GPL-3.0+

from enum import IntEnum

import click


class SwapState(IntEnum):
    Invalid = 0
    AlicePropose = 1
    AliceCancel = 2
    AliceWithdraw = 3
    AliceRefund = 4
    BobAccept = 5
    BobReject = 6
    BobWithdraw = 7


class SwapSide(object):
    __slots__ = ('contract', 'token', 'address', 'amount')

    def __init__(self, contract, token, address, amount):
        # TODO: verify type of contract
        # TODO: verify type of token
        # TODO: verify type of address
        assert isinstance(amount, int)
        self.contract = contract  # ExampleSwap contract proxy
        self.token = token        # ERC20 token contract proxy
        self.address = address    # Of account
        self.amount = amount      # Number of tokens


class Swap(object):
    __slots__ = ('state', 'alice_side', 'bob_side')

    def __init__(self, state, alice_side, bob_side):
        assert isinstance(state, SwapState)
        assert isinstance(alice_side, SwapSide)
        assert isinstance(bob_side, SwapSide)
        self.state = state
        self.alice_side = alice_side
        self.bob_side = bob_side


class SwapProposal(object):
    __slots__ = ('swap', 'proof')

    def __init__(self, swap, proof):
        self.swap = swap
        self.proof = proof

    def cancel(self):
        # TODO: on bob side, submit cancel transaction (as Alice)
        pass

    def wait(self):
        # TODO: wait until Bob decides what to do with the swap
        # Swap been accepted by Bob, Alice can now withdraw
        return SwapConfirmed(self.swap.alice_side)

    def accept(self):
        # TODO: verify allowed balance on bob side
        # TODO: allow balance on Bob side if needed
        # TODO: on bob side, submit accept transaction (as Bob)
        return SwapConfirmed(self.swap.bob_side)

    def reject(self):
        # TODO: on bob side, submit reject transaction (as Bob)
        pass


class SwapConfirmed(object):
    __slots__ = ('side',)

    def __init__(self, side):
        assert isinstance(side, SwapSide)
        self.side = side

    def withdraw(self):
        return True


class SwapManager(object):
    def __init__(self):
        """
        A and B side
        On each side there are Token and ExampleSwap contracts
        """
        pass

    def propose(self, alice_side, bob_side):
        assert isinstance(alice_side, SwapSide)
        assert isinstance(bob_side, SwapSide)
        # TODO: verify allowed balance on Alice side
        # TODO: allow balance on Alice side if needed
        # TODO: submit proposal transaction
        swap = None
        proposal = None
        return SwapProposal(swap, proposal)


@click.command(help="Alice Propose")
def alice_propose():
    pass


@click.command(help="Alice Cancel")
def alice_cancel():
    pass


@click.command()
def alice_refund():
    pass


@click.command()
def alice_withdraw():
    pass


@click.command()
def bob_accept():
    pass


@click.command()
def bob_reject():
    pass


@click.command()
def bob_withdraw():
    pass


COMMANDS = click.Group("swap", help="ExampleSwap wrapper")
COMMANDS.add_command(alice_propose)
COMMANDS.add_command(alice_cancel)
COMMANDS.add_command(alice_refund)
COMMANDS.add_command(alice_withdraw)
COMMANDS.add_command(bob_accept)
COMMANDS.add_command(bob_reject)
COMMANDS.add_command(bob_withdraw)


if __name__ == "__main__":
    COMMANDS.main()
