# Panautomata

[![Build Status](https://travis-ci.org/HarryR/panautomata.svg?branch=master)](https://travis-ci.org/HarryR/panautomata)

This is a research project to make it easy for developers to write smart contracts which run across multiple block-chains without the complex underlying logic that makes it possible.

Think of this as being a cross-chain oracle for events and transactions, or it could potentially be used as a way of integrating legacy systems with the block-chain.

**If you have interesting use cases, or would like to see integration with interesting things, please add a ticket**

**WARNING: this is a work-in progress, use at your own risk**


## ToDo

### General

 * [ ] Improved logging in Python code
 * [ ] Getting started guide
 * [x] ExamplePingPong FSM diagram + documentation
 * [ ] ExampleSwap FSM diagram
 * [ ] Registry/Registrar contract, single entry-point to lookup other contracts?
 * [ ] API for retrieving proofs

### Testing

 * [ ] A2A and B2B 'self-chain' tests, prove event from self
 * [x] Tests for LithiumLink contract
 * [x] PingPong example works end-to-end
 * [ ] Swap example works end-to-end

### Toolchain ToDo

 * [x] Travis CI
 * [x] End-to-end tests under Travis
 * [x] Commit signing
 * [ ] Python coverage / Codeclimate
 * [x] Solidity code coverage
 * [ ] Docker image
 * [ ] Docker image upload from Travis


## Licensing

The project as a whole is GPL-3.0, but individual files may be licensed under the LGPL-3.0. Each file should have a `SPDX-License-Identifier` line at the start, denoting the license.


## Appreciation

Many thanks to [Matthew Di Ferrante](https://github.com/mattdf) and [Robert Sams](https://twitter.com/codedlogic) for providing inspiration and insight, and [Clearmatics Ltd.](https://www.clearmatics.com/) for spending money on interesting things.


## Related Papers / Resources

 * https://comserv.cs.ut.ee/home/files/mutunda_software_engineering_2017.pdf?study=ATILoputoo&reference=25F43764CDF7F7F21F6F674878A5D1BCA7C872F1
 * https://github.com/silkchain/TurboBpmn
 * https://courses.cs.ut.ee/MTAT.03.323/2016_fall/uploads/Main/Sem3.pdf
 * http://rystsov.info/2016/05/01/paxos.html
 * http://ithare.com/chapter-vc-modular-architecture-client-side-on-debugging-distributed-systems-deterministic-logic-and-finite-state-machines/
 * https://www.jamessturtevant.com/posts/Creating-a-Finite-State-Machine-Distributed-Workflow-with-Service-Fabric-Reliable-Actors/
 * https://en.wikipedia.org/wiki/State_machine_replication
 * https://www.quantisan.com/event-driven-finite-state-machine-for-a-distributed-trading-system/
 * https://patents.google.com/patent/US8255852 (lol, math patents)
 * http://learnyousomeerlang.com/finite-state-machines
 * https://msdn.microsoft.com/en-us/library/aa478972.aspx
 * https://projects.spring.io/spring-statemachine/
 * https://bloxroute.com/wp-content/uploads/2018/03/bloXroute-whitepaper.pdf
 * TODO: Add more, filter for relevency


## Related Projects

 * Terra-Bridge - https://medium.com/contractland/introducing-terra-bridge-cross-chain-value-transfers-d857cbb1ee71
 * Cosmos - https://cosmos.network/
 * Polkadot - https://polkadot.network/
