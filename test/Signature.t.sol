// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";

contract SignitureTest is Test {
    // private key = 345
    // public key = vm.addr(privateKey)
    // message = "secret message"
    // vm.sign(private key, message hash)

    function testSignature() public {
        uint256 privateKey = 345;
        address pubKey = vm.addr(privateKey);

        bytes32 messageHash = keccak256("Emma");

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, messageHash);

        address signer = ecrecover(messageHash, v, r, s);

        // let verify the signer is equal the public key
        assertEq(signer, pubKey);

        // now the signer should not be equal to the public key
        bytes32 invalidMessageHash = keccak256("Invalid Message");
        signer = ecrecover(invalidMessageHash, v, r, s);
        assertTrue(signer != pubKey); // != should not be equal to
    }
}
