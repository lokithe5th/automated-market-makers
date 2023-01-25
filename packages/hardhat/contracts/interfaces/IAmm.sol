pragma solidity 0.8.17;
//SPDX-License-Identifier: MIT

interface IAmm {
  /// LP functions
  function deposit(uint256 amount) external returns (uint256);

  function withdraw(uint256 amount) external returns (uint256, uint256);

  /// Swap functions
  function swapAtoB(uint256 amountIn) external returns (uint256);

  function swapBtoA(uint256 amountOut) external returns (uint256);

}
