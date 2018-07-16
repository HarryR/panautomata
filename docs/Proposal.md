# Distributed State Machine Research Proposal

## Preface

Plasma chains solve a small part of the scaling problem by providing a limited communication method between concurrent domains while ensuring that state (or... value?) can only exist in one place at a time, it is by definion a finite state machine of sorts - albeit with significant constraints.

However, what if part of the scaling problem is more than just the transfer of value between concurrent domains? Both Polkadot and Cosmos identified this problem and sought to find a solution - acting as a general purpose messaging layer, but without the right kind of research I believe they're missing a crucial part of the problem; this is something I wish to address to the benefit of not only the Ethereum ecosystem, but for general purpose distributed computation as a concept.

As with storage of value via cryptographic proof of work (hashcash), then arbitrary programmable transactions in a single place (albeit distributed and secured by the Bitcoin network), then the application of general purpose computation to the same problem (Ethereum) - this project aims to strive towards finding the next exponentially useful leap by making it easier for dispirate systems to work together with the same guarantees of everything that they build upon - and more - or at least, to attempt to scratch the surface of the problem.


### Outline

This research project aims to create a more formalised definition of a distributed finite state machine and its limitations specifically in the blockchain and Ethereum context. It will be achieved by creating prototypes of different use-cases which require cross-chain communication and a finite state being maintained in a distributed environment, initially using proof of state from a trusted authority, hand-written solidity contracts that implement the state machines and client-side examples that make operating the state machines seamless to the developer.

The aims for this research project are to:

 1. Make it easy for developers to model, implement and use cross-chain state machines
 2. Realise a notation for distributed state machines, which includes the transfer of state and value, and concurrent states (like workflows, and BPMN)
 3. Determine when state channels can be used, and automatically condense multiple state transitions into fewer on-chain operations
 4. Explore mechanisms to ensure that state transitions are atomic and unidirectional
 5. Reflect upon value versus state, and whether or not game theory can be applied


### Plasma, value versus state

The exit conditions for Plasma have become an interesting talking point because it creates a game-theoretic condition in which adhering the rules is less costly than any gain you could realise from breaking them.

But, what happens when the value of a state isn't deterministic, where there is no zero-sum game, and the value of a single state transition may be unknowable to any observer?

A speculative aim of this research is, by working through many different use cases and the theory of distributed finite state machines, to try to curate an alternate perspective where concurrency is king - rather than just value being in one place at a time.


## Research Deliverables

I firmly believe that there are two aspects to the value of research:

 1. Delivering something that can be used, by people, realistically
 2. Identifying, solving and pushing the edge cases where it can't yet be used

So, what can I deliver that will help make this happen, without getting caught up in grand-scheme-of-things thinking?

 * Further examples, other than ping-pong, remote-token and atomic-swap
 * Notation and visualisation for the state machines
 * Automatic translation from state machine to smart contract
 * Client-side library to make interracting with the state machines easy
 * Documentation of edge cases
   * Limitations of finite state machines (e.g. split/join, concurrency, workflows)
   * State compression, via state channels
 * Proof of concept of state-machine compression (state channels)

Ultimately the aim is to deliver developer tools, libraries and related programs and supporting documentation so that this work can be used and deployed 

## Timespans

Building upon the work in the Panautomata repository:

 * month 1
   * notation of simple distributed state machines
   * proof of concept, translating state machine notation into smart contract and client-side-code
   * integrating generated state machines with solidity code
 * month 2
   * further examples and client-side library improvements
   * pluggable proofing mechanisms
     * proof of concept using Ethereum block headers, merkle-patricia trie receipts etc.
     * research for Polkadot and Cosmos integration
 * month 3
   * documentation of edge cases (concurrency, split, join, failure)
   * analyse latest available research on state channels
   * automatic state compression (state channel) specification, by analysing state machine notation
   * client-side and on-chain state channel tools / libraries / simple proofs of concept
 * month 4
   * extend examples to support state compression
   * proof of concept end-to-end example using state compression
   * proof of concept of automatic state compression
 * month 5
   * retrospective
   * documentation
   * deployment considerations

The month to month goals seem reasonable, well scoped and build ontop of each other, however as with any plan this is speculative - however, at each month the focus will be on making sure that the previous months work is in a usable, tested and publicly consumable state. 

Monthly summaries of work-to-date, progress, achievements and deviations from the plan will be provided, with weekly development updates.
