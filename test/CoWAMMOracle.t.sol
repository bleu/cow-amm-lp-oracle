// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/CoWAMMOracle.sol";
import "./mocks/MockChainlinkOracle.sol";
import "./mocks/MockERC20.sol";
import "./mocks/MockCoWAMMPool.sol";

contract CoWAMMOracleTest is Test {
    CoWAMMOracle public oracle;
    MockChainlinkOracle public token0Oracle;
    MockChainlinkOracle public token1Oracle;
    MockERC20 public token0;
    MockERC20 public token1;
    MockCoWAMMPool public pool;

    function setUp() public {
        // Deploy oracle
        oracle = new CoWAMMOracle();

        // Deploy mock tokens with different decimals
        token0 = new MockERC20(6); // 6 decimals
        token1 = new MockERC20(18); // 18 decimals

        // Deploy mock oracles
        token0Oracle = new MockChainlinkOracle(8); // 8 decimals (Chainlink standard)
        token1Oracle = new MockChainlinkOracle(8); // 8 decimals (Chainlink standard)

        // Deploy mock pool
        pool = new MockCoWAMMPool(address(token0), address(token1));
    }

    function testBasicPriceCalculation() public {
        // Set up token balances in pool
        pool.setBalance(address(token0), 3000 * 1e6); // 3000 token0 (6 decimals)
        pool.setBalance(address(token1), 1 * 1e18); // 1 token1 (18 decimals)
        pool.setTotalSupply(1000 * 1e18); // 1000 LP tokens

        // Set up oracle prices
        // token0: $1 per token
        token0Oracle.setRoundData(1 * 1e8, 100, 100, 1);

        // token1: $3000 per token
        token1Oracle.setRoundData(3000 * 1e8, 100, 100, 1);

        uint256 lpPrice = oracle.getLPTokenPrice(
            address(pool),
            address(token0Oracle),
            address(token1Oracle)
        );

        // Expected price calculation:
        assertEq(lpPrice, 6 * 1e18, "LP price calculation incorrect");
    }
}
