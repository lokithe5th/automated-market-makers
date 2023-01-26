pragma solidity 0.8.17;
//SPDX-License-Identifier: MIT

/**
 * @notice Basic Constant Product Market Maker
 * @author lourens linde
 * @dev This is an implementation of a very basic constant product market maker
 *      1) It holds `k=xy`
 *      2) It implements token swap capability (with fee collection)
 *      3) It allows permissionless deposit and withdrawal
 * 
 * Note: For educational purposes only and not for production use!
 */

import "hardhat/console.sol";
import "./interfaces/IAmm.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BasicCPMM is IAmm {
  /**
   * The two tokens that require a liquidity pool
   */
  IERC20 private tokenA;
  IERC20 private tokenB;

  /**
   * The total liquidity, `k`
   */
  uint256 private totalLiquidity;
  
  /**
   * Tracks user liquidity
   */
  mapping(address => uint256) private liquidity;

  /**
   * The fees charged per swap
   */
  uint256 private fee;

  /**
   * Basis points are useful in financial math
   */
  uint256 private constant BASIS_POINTS = 10_000;

  /**
   * @notice Initializes the LP
   * @param _tokenA The address of the token against which the liquidity is calculated
   * @param _amountA The amount of token A to transfer to the LP
   * @param _tokenB The address of the secondary token
   * @param _amountB The amount of token B to transfer to the LP
   * @return uint256 The total liquidity in the LP
   */
  function init(
    IERC20 _tokenA,
    uint256 _amountA,
    IERC20 _tokenB,
    uint256 _amountB
  ) external returns (uint256) {
    require(_amountA == _amountB, "Require equal amounts of tokens");
    tokenA = _tokenA;
    tokenB = _tokenB;

    fee = 9_970;
    /// Liquidity is used in proportions
    totalLiquidity = _amountA;
    liquidity[msg.sender] = _amountA;
    
    require(tokenA.transferFrom(msg.sender, address(this), _amountA), "Init failed");
    require(tokenB.transferFrom(msg.sender, address(this), _amountB), "Init failed");

    return totalLiquidity;
  }

  /**
   * @notice Allows permissionless provision of liquidity
   * @param amount The number of both token A and token B to provide
   * @return liquidityMinted The amount of liquidity minted by the deposit
   */
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

  /**
   * @notice Allows liquidity providers to withdraw their provided tokens
   * @dev The withdrawal is proportionate to `amount` relative to `totalLiquidity`
   * @param amount The amount of liquidity to withdraw
   * @return tokenAAmount The amount of token A returned to the user
   * @return tokenBAmount The amount of token B returned to the user
   */
  function withdraw(uint256 amount) external returns (uint256 tokenAAmount, uint256 tokenBAmount) {
    require(liquidity[msg.sender] >= amount, "Exceeded liquidity");

    uint256 tokenAReserve = tokenA.balanceOf(address(this));
    uint256 tokenBReserve = tokenB.balanceOf(address(this));

    /// Based on the amount of liquidity provided, determine the amount of tokens to withdraw
    tokenAAmount = (tokenAReserve * amount) / totalLiquidity;
    tokenBAmount = (tokenBReserve * amount) / totalLiquidity;

    liquidity[msg.sender] -= amount;
    totalLiquidity -= amount;

    require(tokenA.transfer(msg.sender, tokenAAmount), "Transfer Failed");
    require(tokenB.transfer(msg.sender, tokenBAmount), "Transfer Failed");
  }

  /**
   * @notice Swaps from token A to token B
   * @param amountIn The amount of token A to swap for token B
   * @return tokensReceived The amount of token B received
   */
  function swapAtoB(uint256 amountIn) external returns (uint256 tokensReceived) {
    tokensReceived = price(amountIn, tokenA.balanceOf(address(this)), tokenB.balanceOf(address(this)));

    tokenA.transferFrom(msg.sender, address(this), amountIn);
    tokenB.transfer(msg.sender, tokensReceived);
  }

  /**
   * @notice Swaps from token B to token A
   * @param amountIn The amount of token B to swap for token A
   * @return tokensReceived The amount of token B received
   */
  function swapBtoA(uint256 amountIn) external returns (uint256 tokensReceived) {
    tokensReceived = price(amountIn, tokenA.balanceOf(address(this)), tokenB.balanceOf(address(this)));

    tokenB.transferFrom(msg.sender, address(this), amountIn);
    tokenA.transfer(msg.sender, tokensReceived);
  }

  /**
   * @notice Provides the amount of tokens returned for a given `inputAmount`
   * @param inputAmount The amount of a given token to provide to the LP
   * @param inputReserve The amount of the input tokens in the LP reserve
   * @param outputReserve The amount of output tokens in the LP reserve
   * @return uint256 The amount of output tokens to receive given the input params and reserves
   */
  function price(
    uint256 inputAmount,
    uint256 inputReserve,
    uint256 outputReserve
  ) public view returns (uint256) {
    inputAmount = (fee > 0) ? inputAmount * fee : inputAmount;
    uint256 numerator = inputAmount * outputReserve;
    uint256 denominator = (fee > 0) ? (inputReserve * BASIS_POINTS) + inputAmount : inputReserve + inputAmount;
    return numerator / denominator;
  }

  /**
   * @notice Allows a user to set the fee
   * @dev Fees are expressed in Basis Points
   * @param newFee The new fee for token swaps
   */
  function setFee(uint256 newFee) external {
    fee = newFee;
  }

  function viewProvidedLiquidity(address provider) external view returns (uint256) {
    return liquidity[provider];
  }

  // to support receiving ETH by default
  receive() external payable {}
  fallback() external payable {}
}
