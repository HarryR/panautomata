## Cross-Token Example

The Cross-Token example allows for Ether to be locked on chain A, proof of the deposit is presented on chain B to redeem tokens of equivalent value (1:1). The tokens on chain B can be used like any normal token. Any holder of a token on chain B can 'burn' them, then present proof of burn to the lock contract on chain A to retrieve the original asset. The tokens are fully fungible.

Because the ether is Locked on chain A it cannot be used until it has been Burned on chain B. This ensures the value is only ever in one place at a time.

The relevent source code files are:
 
 * [tokenproxy.py](../python/panautomata/example/tokenproxy.py)
 * [ExampleCrossToken.sol](../solidity/contracts/example/ExampleCrossToken.sol)

## State Machine

![Cross Token State Diagram](https://i.imgur.com/HSzZTcJ.png)

Alice and Bob can use their key pair / account on both Chain A and Chain B.

However, the Lock contract only exists on Chain A, and the Token contract only exists on chain B.

The `Lithium` contract is really two daemons and two contracts, but it's represented here as a single entity. It compiles events from chain A and publishes the merkle roots on chain B, and visa versa.

Source code for use with WebSequenceDiagrams.com:

```
title Cross Token

opt Alice Deposits 1000 wei
Alice->Lock: Deposit(1000wei)
Alice-->Lock: 1000wei
Lock-->>Lithium: observe deposit
Alice->Token: Redeem(1000wei) with proof
Token<-->Lithium: verify proof
Token-->>Alice: balance +1000 tokens
end

opt Alice gives bob 500
Alice->Token: Transfer(500, Bob)
Token-->>Alice: balance -500 tokens
Token-->>Bob: balance +500 tokens
end

opt Bob burns and withdraws
Bob->Token: Burn(500)
Token-->>Bob: balance -500 tokens
Token-->>Lithium: observe burn
Bob->Lock: Withdraw(500) with proof
Lock<-->Lithium: verify proof
Lock-->>Bob: 500wei
end
```