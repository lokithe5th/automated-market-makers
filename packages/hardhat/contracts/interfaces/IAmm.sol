pragma solidity 0.8.17;
//SPDX-License-Identifier: MIT

interface IAmm {
  /// LP functions
  function deposit(address token, uint256 amount) external;

  function withdraw(address token, uint256 amount) external;

  /// Swap functions
  function swapTokenIn(address from, address to, uint256 amountIn) external;

  function swapTokenOut(address from, address to, uint256 amountOut) external;

}
