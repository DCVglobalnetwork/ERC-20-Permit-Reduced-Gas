// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/ERC20Permit.sol";
import "../src/GaslessTokenTransfer.sol";

contract GaslessTokenTransferTest is Test {
    ERC20Permit private token;
    GaslessTokenTransfer private gasless;
    // we need to come up with a private key then call vm addr to get the address
    uint256 constant SENDER_PRIVATE_KEY = 111;
    // we need the sender and we need the reciever
    address sender;
    address receiver;
    uint256 constant AMOUNT = 1000;
    uint256 constant FEE = 10;

    function setUp() public {
        sender = vm.addr(SENDER_PRIVATE_KEY);
        receiver = address(2);
        // the sender wil be signing a message which will be passed to the ERC2OPermit contract
        token = new ERC20Permit("Test", "TEST", 18);
        token.mint(sender, AMOUNT + FEE);

        gasless = new GaslessTokenTransfer();
    }
    // we are going to testing is the sender is going to sign up permit message
    // and this contract will call the GaslessTokenTransfer contract and we expect the token to be transferred
    // from the sender to receiver and this contract will receive some of the fees
    function testValidSign() public {
        uint256 deadline = block.timestamp + 60;

        // Sender - prepare permit signature
        bytes32 permitHash = _getPermitHash(
            sender,
            address(gasless),
            AMOUNT + FEE,
            token.nonces(sender),
            deadline
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            SENDER_PRIVATE_KEY,
            permitHash
        );

        // Execute transfer
        gasless.send(
            address(token),
            sender,
            receiver,
            AMOUNT,
            FEE,
            deadline,
            v,
            r,
            s
        );

        // Check balances
        assertEq(token.balanceOf(sender), 0, "sender balance"); // balance of sender
        assertEq(token.balanceOf(receiver), AMOUNT, "receiver balance"); // balance of receiver
        assertEq(token.balanceOf(address(this)), FEE, "fee"); // balance of this contract
    }

    function _getPermitHash(
        address owner,
        address spender,
        uint256 value,
        uint256 nonce,
        uint256 deadline
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                            ),
                            owner,
                            spender,
                            value,
                            nonce,
                            deadline
                        )
                    )
                )
            );
    }
}
