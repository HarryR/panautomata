# Atomic Swap Example

The atomic swap example uses cross-chain proofs of transactions and events to perform an atomic cross-chain token swap between two parties in a way that, in an atomic fashion, either the swap can happen or both can be refunded - this is an absolute guarantee as long as the event proofing source is updated, unlike using a HTLC (pre-image lock with expiry) where one side can be left at a disadvantage if they miss the expiry time.


## State Machine

![Atomic Swap State Machine](https://i.imgur.com/RnHKrn1.png)
