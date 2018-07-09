// Copyright (c) 2018 HarryR. All Rights Reserved.
// SPDX-License-Identifier: GPL-3.0+

pragma solidity 0.4.24;

import "truffle/Assert.sol";
import "../contracts/LithiumLink.sol";


contract TestLithiumLink
{
    function testLinkUpdate () public
    {
        uint256[] memory l_roots = new uint256[](2);
        l_roots[0] =
            18816486038835455661079455548344429740997917459031915165980477461056310113737;
        l_roots[1] = 0x0ecee24d0107cfaa2eb4977d9a9c76e91c955b504820a15130928c180f3d3615;

        uint64 block_height = 10;

        LithiumLink l_link = new LithiumLink(1, block_height - 1);

        l_link.Update(block_height - 1, l_roots);

        Assert.equal( l_link.GetHeight(), block_height, "Link height incorrect!" );

        Assert.equal( l_link.GetMerkleRoot(block_height), l_roots[0], "Merkle Root incorrect!" );

        Assert.equal( l_link.GetBlockHash(block_height), l_roots[1], "Block Hash incorrect!" );

        // TODO: update again?
    }
}