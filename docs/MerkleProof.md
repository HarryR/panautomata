# Short Merkle Proofs

All integers are encoded in big-endian format (most significant bit first).

## Leaf Format

| block hash | transaction index | log index | HASH(leaf_data) |
| ---------- | ----------------- | --------- | --------------- |
|  32 bytes  |      32 bits      |  32 bits  |    32 bytes     |
|            |      integer      |  integer  |    keccak256    |

## Proof Format

| block height | transaction index | log index |  Path 0  |  Path N  | .. |
| ------------ | ----------------- | --------- | -------- | -------- | -- |
|              |                   |           |          | optional | .. |
|   64 bits    |      32 bits      |  32 bits  | 32 bytes | 32 bytes | .. |
|   integer    |      integer      |  integer  |          |          |    |


The proof requires additional data for the leaf to be reconstructed, namely the `block_hash` field and the `leaf_data` field. The `block_hash` field is retrieved from on-chain storage based on the `block_height` field, and the `leaf_data` field is reconstructed using parameters from the contract and any other information which may be specific to the protocol or application being implemented

Each proof is at at minimum 48 bytes (with the minimum of 1 item in the Merkle tree path), and will increase in multiples of 32 bytes depending on the length of the path.


# Ethereum Leaf Format

For Ethereum events and transactions only the absolutely necessary information is recorded in each leaf.

## Transaction

| from address | to address |  value   | HASH(selector,args) |
| ------------ | ---------- | -------- | ------------------- |
|  20 bytes    |  20 bytes  | 256 bits |       32 byte       |
|  address     |  address   | integer  |   keccak-256 hash   |

## Event

| contract address |   topic   |  HASH(args) |
| ---------------- | --------- | ----------- |
|     20 bytes     |  32 bytes |   32 bytes  |
|     address      |           |   keccak256 |
