# Ping-Pong Example

The Ping Pong example uses cross-chain proofs of transactions and events to keep a distributed state machine running. The state machine can only be executed in the correct order by the same account across the two chains.

Every transaction and event emitted on either chain is provable via a merkle tree proof, where the merkle root is uploaded to either chain, allowing an on-chain contract from one chain to prove a transaction or event occurred on another chain.

The two relevent files are:

 * [pingpong.py](python/panautomata/example/pingpong.py)
 * [ExamplePingPong.sol](solidity/contracts/example/ExamplePingPong.sol)


## Operation (taken from `ExamplePingPong.sol` comments)

The ping pong example requires two contracts on two separate networks.
It demonstrates the passing of both events and transactions to each other.

The process is started on one side. Lets call that side 'A'
Proof of the Start transaction is sent to the other side. Lets call that side 'B'
`B` then emits an event acknowledging proof of the `Start` transaction, the 'Ping'
Proof of that event is passed to `A`, which in turn emits the 'Pong' event.

At each step the counter for the Guid is incremented, this ensures that the
next event processed by either side is what was expected.

The 'Start' transaction binds the process between two contracts on different
networks, and specifies the 'Prover' contract they use. This binds the `A` side
to a specific configuration.

Then the `ReceiveStart` function binds `B`s side to the same details.

After that both sides can exchange events without having to specify the full
details upon every call to `ReceivePing` and `ReceievePong`.


## State Machine

![Ping Pong State Machine](https://i.imgur.com/ZV9OLTI.png)

Source code for use with WebSequenceDiagrams.com

```
title Ping Pong

Player->Alice: Start
Alice-->>Prover: Proof of Start
Prover->Bob: ReceiveStart
loop forever
  Bob-->>Prover: emit Ping
  Prover->Alice: ReceievePing
  Alice-->>Prover: emit Pong
  Prover->Bob: ReceivePong
end
```

