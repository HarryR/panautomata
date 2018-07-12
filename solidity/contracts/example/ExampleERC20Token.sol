pragma solidity 0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol";


contract ExampleERC20Token is MintableToken {
    string public name = "EXAMPLE ERC20";
    string public symbol = "TEST";
    uint8 public decimals = 18;

    modifier hasMintPermission() {
        _;
    }


    function getCurrentOwner() public view returns (address) {
        return msg.sender;
    }
}