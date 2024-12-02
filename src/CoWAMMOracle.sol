// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {ChainlinkTWAP} from "./libraries/ChainlinkTWAP.sol";
import {AggregatorV3Interface} from "./interfaces/AggregatorV3Interface.sol";
import {IBPool} from "./interfaces/IBPool.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract CoWAMMOracle {
    using Math for uint256;

    uint80 public constant NUM_ROUNDS = 2;

    /// @notice Calculates the price of LP token based on underlying assets
    /// @param poolAddress Address of the Balancer pool
    /// @param token0Oracle Chainlink oracle for token0
    /// @param token1Oracle Chainlink oracle for token1
    /// @param twapNumRounds Number of rounds to calculate TWAP
    /// @return lpPrice Price of one LP token in USD (with 18 decimals)
    function getLPTokenPrice(
        address poolAddress,
        address token0Oracle,
        address token1Oracle,
        uint80 twapNumRounds
    ) external view returns (uint256 lpPrice) {
        IBPool pool = IBPool(poolAddress);

        // Get pool tokens
        address[] memory tokens = pool.getFinalTokens();
        require(tokens.length == 2, "Invalid number of tokens");

        // Get token balances and decimals
        uint256 balance0 = pool.getBalance(tokens[0]);
        uint256 balance1 = pool.getBalance(tokens[1]);

        uint8 decimals0 = IERC20(tokens[0]).decimals();
        uint8 decimals1 = IERC20(tokens[1]).decimals();
        uint256 poolDecimals = pool.decimals();

        // Get token prices from Chainlink
        uint256 price0 = ChainlinkTWAP.getTWAP(token0Oracle, twapNumRounds);
        uint256 price1 = ChainlinkTWAP.getTWAP(token1Oracle, twapNumRounds);

        // Normalize balances to 18 decimals
        uint256 token0Value = balance0.mulDiv(price0, 10 ** decimals0);
        uint256 token1Value = balance1.mulDiv(price1, 10 ** decimals1);

        // Calculate total value in the pool
        uint256 totalValue = token0Value + token1Value;

        // Get total supply of LP tokens
        uint256 totalSupply = pool.totalSupply();

        // Calculate price per LP token
        lpPrice = totalValue.mulDiv(10 * poolDecimals, totalSupply);
    }
}
