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
  ) external returns (uint256) {
    tokenA = _tokenA;
    tokenB = _tokenB;
    fee = 9_970;
  }

  function deposit(address token, uint256 amount) {
    require(token == address(tokenA) || token == address(tokenB), "Invalid token");
  }

  function swapTokenIn(
    address from,
    address to,
    uint256 amountIn
  ) external returns (uint256) {

  }

  function swapTokenOut(
    address from,
    address to,
    uint256 amountOut
  ) external returns (uint256) {

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
