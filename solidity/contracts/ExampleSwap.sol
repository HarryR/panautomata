pragma solidity 0.4.24;

import "./ERC20.sol";

import "./ProofVerifierInterface.sol";


contract ExampleSwap
{
    ProofVerifierInterface internal m_verifier;

    struct Swap {
        ERC20 currency;
        address depositor;
        address receiver;
        uint256 value;
    }

    event OnDeposit (uint256 swap_id, address currency, address depositor, address receiver, uint256 value);

    mapping(uint256 => Swap) internal m_swaps;

    constructor( ProofVerifierInterface verifier )
        public
    {
        m_verifier = verifier;
    }

    /**
    * @param in_currency Address of ERC20 token
    * @param in_receiver Account authorised to withdraw
    * @param in_value Amount of tokens
    */
    function Deposit( uint256 in_swap_id, ERC20 in_currency, address in_receiver, uint256 in_value )
        public returns (bool)
    {
        require( in_receiver != address(0x0) );
        require( in_value > 0 );

        // Transfer N units of currency, verify balance before and after
        // This catches wonky edge-cases with poorly written ERC20 tokens
        // This also verifies the ERC20 token functions correctly

        uint256 balance_before = in_currency.balanceOf(this);
        require( in_currency.transferFrom(msg.sender, this, in_value) );
        uint256 balance_after = in_currency.balanceOf(this);
        require( (balance_after - balance_before) == in_value );

        // Save the swap
        m_swaps[in_swap_id] = Swap(in_currency, msg.sender, in_receiver, in_value);

        emit OnDeposit(in_swap_id, in_currency, msg.sender, in_receiver, in_value);

        return true;
    }

    /**
    * When given proof that a payment exists in a proof uploaded to IonLink
    * it will allow the sender to withdraw tokens of the specified value.
    *
    * @param in_swap_id Unique Swap ID
    * @param in_block_id LithiumLink block ID
    * @param in_proof Merkle proof
    */
    function Withdraw( uint256 in_swap_id, uint256 in_block_id, uint256[] in_proof )
        public returns (bool)
    {
        Swap storage swap = GetSwap(in_swap_id);
        ERC20 currency = swap.currency;

        require( swap.receiver == msg.sender );

        // Proof that other side has been deposited
        uint256 leaf_hash = uint256(keccak256(abi.encodePacked(
            msg.sender,
            address(this),
            address(currency)
        )));
        require( m_verifier.Verify(in_block_id, leaf_hash, in_proof) );
    
        // Perform transfer and verify balance has been reduced accordingly
        uint256 balance_before = currency.balanceOf(this);
        swap.currency.transfer(swap.receiver, swap.value);
        uint256 balance_after = currency.balanceOf(this);
        require( (balance_after - balance_before) == swap.value );

        return true;
    }

    function GetSwap( uint256 in_swapid )
        internal view returns (Swap storage out_swap)
    {
        out_swap = m_swaps[in_swapid];
        require( out_swap.depositor != address(0x0) );
        require( out_swap.value > 0 );
    }
}
