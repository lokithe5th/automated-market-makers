pragma solidity 0.8.17;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {

  constructor(string memory name, string memory symbol) ERC20(name, symbol) {
    _mint(msg.sender, 200*10**18);
  }

  function mint(address to, uint256 amount) external {
    _mint(to, amount);
  }

  // to support receiving ETH by default
  receive() external payable {}
  fallback() external payable {}
}
