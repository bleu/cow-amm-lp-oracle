// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {IBPool} from "../../src/interfaces/IBPool.sol";
import {MockERC20} from "./MockERC20.sol";

contract MockCoWAMMPool is IBPool, MockERC20 {
    address[] private _tokens;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _weights;
    uint256 private _totalSupplyPool;

    constructor(address token0, address token1) MockERC20(18) {
        _tokens = new address[](2);
        _tokens[0] = token0;
        _tokens[1] = token1;

        // Default to equal weights (50-50)
        _weights[token0] = 0.5e18;
        _weights[token1] = 0.5e18;
    }

    function setBalance(address token, uint256 balance) external {
        _balances[token] = balance;
    }

    function setWeight(address token, uint256 weight) external {
        _weights[token] = weight;
    }

    function getNumTokens() external view override returns (uint256) {
        return _tokens.length;
    }

    function getFinalTokens()
        external
        view
        override
        returns (address[] memory)
    {
        return _tokens;
    }

    function getNormalizedWeight(
        address token
    ) external view override returns (uint256) {
        return _weights[token];
    }

    function getBalance(
        address token
    ) external view override returns (uint256) {
        return _balances[token];
    }
}
