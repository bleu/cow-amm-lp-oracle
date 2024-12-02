// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {IERC20} from "./IERC20.sol";

interface IBPool is IERC20 {
    /**
     * @notice Gets the number of tokens in the pool
     * @return numTokens The number of tokens in the pool
     */
    function getNumTokens() external view returns (uint256 numTokens);

    /**
     * @notice Gets the final array of tokens in the pool, after finalization
     * @return tokens The array of tokens in the pool
     */
    function getFinalTokens() external view returns (address[] memory tokens);

    /**
    /**
     * @notice Gets the normalized weight of a token in the pool
     * @param token The address of the token to check
     * @return normWeight The normalized weight of the token in the pool
     */
    function getNormalizedWeight(
        address token
    ) external view returns (uint256 normWeight);

    /**
     * @notice Gets the Pool's ERC20 balance of a token
     * @param token The address of the token to check
     * @return balance The Pool's ERC20 balance of the token
     */
    function getBalance(address token) external view returns (uint256 balance);
}
