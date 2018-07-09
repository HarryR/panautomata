# Short Merkle Proofs


## Leaf Format

```
 |   64 bits  |   64 bits    |      32 bits      |  32 bits  |    32 bytes     |
 |   integer  |   integer    |      integer      |  integer  |     

 +------------+--------------+-------------------+-----------+-----------------+
 | network id | block height | transaction index | log index | HASH(leaf_data) |
 +------------+--------------+-------------------+-----------+-----------------+

```

## Proof Format

```
              |   64 bits    |      64 bits      |  32 bits  | 32 bytes | 32 bytes | .. 
              |   integer    |      integer      |  integer  |          |          |

                                                                        [ optional   
              +--------------+-------------------+-----------+----------+----------+--
              | block height | transaction index | log index |  Path 0  |  Path N  | ..
              +--------------+-------------------+-----------+----------+----------+--
```

The proof requires additional data for the leaf to be reconstructed, namely the `network_id` field and the `leaf_data` field.

Each proof is at at minimum 48 bytes (with the minimum of 1 item in the Merkle tree path), and will increase in multiples of 32 bytes depending on the length of the path.