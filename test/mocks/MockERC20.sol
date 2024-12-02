// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "../../src/interfaces/IERC20.sol";

// Mock ERC20 Token
contract MockERC20 is IERC20 {
    uint8 private immutable _decimals;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(uint8 decimals_) {
        _decimals = decimals_;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function setTotalSupply(uint256 supply) external {
        _totalSupply = supply;
    }

    function balanceOf(
        address account
    ) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address, uint256) external pure override returns (bool) {
        return true;
    }

    function allowance(
        address,
        address
    ) external pure override returns (uint256) {
        return 0;
    }

    function approve(address, uint256) external pure override returns (bool) {
        return true;
    }

    function transferFrom(
        address,
        address,
        uint256
    ) external pure override returns (bool) {
        return true;
    }
}
