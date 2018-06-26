// Copyright (c) 2018 HarryR. All Rights Reserved.
// SPDX-License-Identifier: LGPL-3.0+

pragma solidity 0.4.24;

/**
 * Implements Merkle algorithm from https://github.com/HarryR/solcrypto
 * MSB of each item in path is used as the left/right indicator flag
 */
library Merkle
{
    // 1 << 255
    uint256 internal constant ONE_SHL_255 = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    /**
    * Hashes two items to form a merkle tree node
    */
    function HashNode( uint256 a, uint256 b )
        internal pure
        returns (uint256)
    {
        uint256 x = uint256(keccak256(abi.encodePacked(a, b)));

        // Clears MSB from result, left/right of node is stored there
        // This allows path to be an array of 256bit values
        // And avoids a separate left/right flag bit taking up extra space
        if (x & ONE_SHL_255 > 0)
            return x ^ ONE_SHL_255;

        return x;
    }

    /*
    * Test case:
    * "0x1a792cf089bfa56eae57ffe87e9b22f9c9bfe52c1ac300ea1f43f4ab53b4b794","0x2584db4a68aa8b172f70bc04e2e74541617c003374de6eb4b295e823e5beab01",["0x1ab0c6948a275349ae45a06aad66a8bd65ac18074615d53676c09b67809099e0","0x093fd25755220b8f497d65d2538c01ed279c131f63e42b2942867f2bd6622486","0xb1d101d9a9d27c3a8ed9d1b6548626eacf3d19546306117eb8af547d1e97189e","0xcb431dd627bc8dcfd858eae9304dc71a8d3f34a8de783c093188bb598eeafd04"]
    */
    function Verify( uint256 root, uint256 leaf_hash, uint256[] path )
        internal pure
        returns (bool)
    {
        // Zero the MSB, if set
        if (leaf_hash & ONE_SHL_255 > 0)
            leaf_hash ^= ONE_SHL_255;

        // No path? Leaf is hash of item
        if (path.length == 0)
            return leaf_hash == root;

        uint256 node = leaf_hash;
        uint256 item;

        for (uint256 i = 0; i < path.length; i++)
        {
            item = path[i];

            if ((item & ONE_SHL_255) > 0) {
                node = HashNode(node, item ^ ONE_SHL_255);
            } else {
                node = HashNode(item, node);
            }
        }
        
        return node == root;
    }
}