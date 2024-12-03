// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {ChainlinkUtils} from "./libraries/ChainlinkUtils.sol";
import {AggregatorV3Interface} from "./interfaces/AggregatorV3Interface.sol";
import {IBPool} from "./interfaces/IBPool.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {BNum} from "./BNum.sol";
import {BConst} from "./BConst.sol";

contract CoWAMMOracle is BNum {
    /**
     * @notice Calculates the balanced reserves for a token pair given their prices and invariant
     * TODO: Implement weighted math
     * @param invariant The pool's invariant (k) value from the constant product formula
     * @param tokenPrice The price of the token whose reserve is being calculated
     * @param otherTokenPrice The price of the other token in the pair
     * @return The balanced reserve amount for the token, scaled by BONE
     * @dev Formula used: reserve = √(invariant * otherTokenPrice) / √(tokenPrice)
     */
    function calculateBalancedReserves(
        uint256 invariant,
        uint256 tokenPrice,
        uint256 otherTokenPrice
    ) internal pure returns (uint256) {
        return
            bdiv(
                bmul(bsqrt(invariant), bsqrt(otherTokenPrice)),
                bsqrt(tokenPrice)
            );
    }

    /**
     * @notice Retrieves the token balance from a Balancer pool and normalizes it to 18 decimals
     * TODO: Implement weighted math
     * @param pool The address of the Balancer pool contract
     * @param token The address of the token whose balance is being queried
     * @return The normalized token balance with 18 decimal places
     */
    function getBalanceWith18Decimals(
        IBPool pool,
        address token
    ) internal view returns (uint256) {
        IBPool bPool = IBPool(pool);
        uint256 balance = bPool.getBalance(token);
        uint8 decimals = IERC20(token).decimals();
        return Math.mulDiv(balance, 10 ** 18, 10 ** decimals);
    }

    /// @notice Calculates the price of LP token based on underlying assets
    /// TODO: Implement weighted math. For now it assumes 50/50 pool for simplicity
    /// @param poolAddress Address of the Balancer pool
    /// @param token0Oracle Chainlink oracle for token0
    /// @param token1Oracle Chainlink oracle for token1
    /// @return lpPrice Price of one LP token in USD (with 18 decimals)
    function getLPTokenPrice(
        address poolAddress,
        address token0Oracle,
        address token1Oracle
    ) external view returns (uint256) {
        IBPool pool = IBPool(poolAddress);

        // Get pool tokens
        address[] memory tokens = pool.getFinalTokens();
        require(tokens.length == 2, "Invalid number of tokens");

        // Calculate invariant
        // TODO: Implement weighted math
        uint256 invariant = bmul(
            getBalanceWith18Decimals(pool, tokens[0]),
            getBalanceWith18Decimals(pool, tokens[1])
        );

        // Get token prices from Chainlink
        // use 18 decimals to math BMath
        // TODO: use TWAP
        uint256 price0 = ChainlinkUtils.getPriceWithDecimals(token0Oracle, 18);
        uint256 price1 = ChainlinkUtils.getPriceWithDecimals(token1Oracle, 18);

        uint256 reserves0Balanced = calculateBalancedReserves(
            invariant,
            price0,
            price1
        );
        uint256 reserves1Balanced = calculateBalancedReserves(
            invariant,
            price1,
            price0
        );

        uint256 token0Value = bmul(reserves0Balanced, price0);
        uint256 token1Value = bmul(reserves1Balanced, price1);

        uint256 totalValue = badd(token0Value, token1Value);
        uint256 totalSupply = pool.totalSupply();

        // Considers that the BCoWAMM pool always has 18 decimals and return the price with 18 decimals
        return bdiv(totalValue, totalSupply);
    }
}
