pragma solidity 0.8.17;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "./interfaces/IAmm.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol"; 
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract ConstantProductAMM is IAmm {
  IERC20 private tokenA;
  IERC20 private tokenB;

  uint256 private totalLiquidity;
  mapping(address => uint256) private liquidity;

  uint256 private fee;

  uint256 private constant BASIS_POINTS = 10_000;

  function init(
    IERC20 _tokenA,
    uint256 _amountA,
    IERC20 _tokenB,
    uint256 _amountB
  ) external returns (uint256 totalLiquidity) {
    require(_amountA == _amountB, "Require equal amounts of tokens");
    tokenA = _tokenA;
    tokenB = _tokenB;

    fee = 9_970;
    /// Liquidity is used in proportions
    totalLiquidity = _amountA;
    liquidity[msg.sender] = _amountA;
    
    require(tokenA.transferFrom(msg.sender, address(this), _amountA), "Init failed");
    require(tokenB.transferFrom(msg.sender, address(this), _amountB), "Init failed");
  }

  function deposit(uint256 amount) external returns (uint256 liquidityMinted) {
    uint256 tokenAReserve = tokenA.balanceOf(address(this));
    /// The amount of liquidity in the contract * newTokens / tokenAReserve
    /// Because tokenA : tokenB == 1 : 1, it doesn't matter if we use reserve B or A
    liquidityMinted = (totalLiquidity * amount) / tokenAReserve;

    liquidity[msg.sender] += liquidityMinted;
    totalLiquidity += liquidityMinted;

    require(tokenA.transferFrom(msg.sender, address(this), amount), "Transfer A failed");
    require(tokenB.transferFrom(msg.sender, address(this), amount), "Transfer B failed");
  }

  function withdraw(uint256 amount) external returns (uint256 tokenAAmount, uint256 tokenBAmount) {
    require(liquidity[msg.sender] >= amount, "Exceeded liquidity");

    uint256 tokenAReserve = tokenA.balanceOf(address(this));
    uint256 tokenBReserve = tokenB.balanceOf(address(this));

    /// Based on the amount of liquidity provided, determine the amount of tokens to withdraw
    tokenAAmount = (tokenAReserve * amount) / totalLiquidity;
    tokenBAmount = (tokenBReserve * amount) / totalLiquidity;

    liquidity[msg.sender] -= tokenAAmount;
    totalLiquidity -= tokenAAmount;

    require(tokenA.transfer(msg.sender, tokenAAmount), "Transfer Failed");
    require(tokenB.transfer(msg.sender, tokenBAmount), "Transfer Failed");
  }

  function swapAtoB(uint256 amountIn) external returns (uint256 tokensReceived) {
    tokensReceived = price(amountIn, tokenA.balanceOf(address(this)), tokenB.balanceOf(address(this)));

    tokenA.transferFrom(msg.sender, address(this), amountIn);
    tokenB.transfer(msg.sender, tokensReceived);
  }

  function swapBtoA(uint256 amountIn) external returns (uint256 tokensReceived) {
    tokensReceived = price(amountIn, tokenA.balanceOf(address(this)), tokenB.balanceOf(address(this)));

    tokenB.transferFrom(msg.sender, address(this), amountIn);
    tokenA.transfer(msg.sender, tokensReceived);
  }

  function price(
    uint256 inputAmount,
    uint256 inputReserve,
    uint256 outputReserve
  ) public view returns (uint256) {
    inputAmount *= fee;
    uint256 numerator = inputAmount * outputReserve;
    uint256 denominator = (inputReserve * 1_000) + inputAmount;
    return numerator / denominator;
  }


  // to support receiving ETH by default
  receive() external payable {}
  fallback() external payable {}
}
