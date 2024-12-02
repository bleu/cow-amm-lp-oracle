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
        pool = new MockCoWAMMPool(address(token0), address(token1), 18); // 18 decimals for LP token
    }

    function testBasicPriceCalculation() public {
        // Set up token balances in pool
        pool.setBalance(address(token0), 1000 * 1e6); // 1000 token0 (6 decimals)
        pool.setBalance(address(token1), 1000 * 1e18); // 1000 token1 (18 decimals)
        pool.setTotalSupply(1000 * 1e18); // 1000 LP tokens

        // Set up oracle prices
        // token0: $1 per token
        token0Oracle.setRoundData(1, 1 * 1e8, 100, 100, 1);
        token0Oracle.setRoundData(2, 1 * 1e8, 200, 200, 2);

        // token1: $2 per token
        token1Oracle.setRoundData(1, 2 * 1e8, 100, 100, 1);
        token1Oracle.setRoundData(2, 2 * 1e8, 200, 200, 2);

        uint256 lpPrice = oracle.getLPTokenPrice(
            address(pool),
            address(token0Oracle),
            address(token1Oracle),
            2
        );

        // Expected price calculation:
        // token0Value = 1000 * $1 = $1000
        // token1Value = 1000 * $2 = $2000
        // totalValue = $3000
        // LP price = $3000 / 1000 = $3 per LP token
        assertEq(lpPrice, 3 * 1e18, "LP price calculation incorrect");
    }

    function testDifferentDecimals() public {
        // Set up token balances with different decimal places
        pool.setBalance(address(token0), 1000 * 1e6); // 1000 token0 (6 decimals)
        pool.setBalance(address(token1), 2000 * 1e18); // 2000 token1 (18 decimals)
        pool.setTotalSupply(1500 * 1e18); // 1500 LP tokens

        // Set up oracle prices
        token0Oracle.setRoundData(1, 2 * 1e8, 100, 100, 1); // $2 per token0
        token0Oracle.setRoundData(2, 2 * 1e8, 200, 200, 2);

        token1Oracle.setRoundData(1, 1 * 1e8, 100, 100, 1); // $1 per token1
        token1Oracle.setRoundData(2, 1 * 1e8, 200, 200, 2);

        uint256 lpPrice = oracle.getLPTokenPrice(
            address(pool),
            address(token0Oracle),
            address(token1Oracle),
            2
        );

        // Expected price calculation:
        // token0Value = 1000 * $2 = $2000
        // token1Value = 2000 * $1 = $2000
        // totalValue = $4000
        // price per LP = $4000 / 1500 ≈ $2.67 per LP token
        assertApproxEqAbs(
            lpPrice,
            2.67e18,
            0.01e18,
            "LP price calculation with different decimals incorrect"
        );
    }

    function testPriceWithTWAP() public {
        pool.setBalance(address(token0), 1000 * 1e6);
        pool.setBalance(address(token1), 1000 * 1e18);
        pool.setTotalSupply(1000 * 1e18);

        // Set up changing prices for TWAP
        token0Oracle.setRoundData(1, 1 * 1e8, 100, 100, 1);
        token0Oracle.setRoundData(2, 2 * 1e8, 200, 200, 2);
        token0Oracle.setRoundData(3, 3 * 1e8, 300, 300, 3);

        token1Oracle.setRoundData(1, 2 * 1e8, 100, 100, 1);
        token1Oracle.setRoundData(2, 3 * 1e8, 200, 200, 2);
        token1Oracle.setRoundData(3, 4 * 1e8, 300, 300, 3);

        uint256 lpPrice = oracle.getLPTokenPrice(
            address(pool),
            address(token0Oracle),
            address(token1Oracle),
            3
        );

        // Price should reflect TWAP values
        assertTrue(lpPrice > 0, "LP price should be positive");
    }

    function testInvalidPoolTokenCount() public {
        // Deploy pool with wrong number of tokens
        MockCoWAMMPool invalidPool = new MockCoWAMMPool(
            address(token0),
            address(0), // Invalid second token
            18
        );

        vm.expectRevert("Invalid number of tokens");
        oracle.getLPTokenPrice(
            address(invalidPool),
            address(token0Oracle),
            address(token1Oracle),
            2
        );
    }
}
