// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../mocks/MockChainlinkOracle.sol";

contract ChainlinkTWAPTest is Test {
    using ChainlinkTWAP for address;

    MockChainlinkOracle public oracle;

    function setUp() public {
        // Create oracle with 8 decimals
        oracle = new MockChainlinkOracle(8);
    }

    function testBasicTWAP() public {
        // Set up 3 rounds of data
        // Round 1: Price = 1000 at t=100
        oracle.setRoundData(1, 1000 * 1e8, 100, 100, 1);
        // Round 2: Price = 2000 at t=200
        oracle.setRoundData(2, 2000 * 1e8, 200, 200, 2);
        // Round 3: Price = 3000 at t=300
        oracle.setRoundData(3, 3000 * 1e8, 300, 300, 3);

        // Calculate TWAP for 3 rounds
        uint256 twap = address(oracle).getTWAP(3);

        // Expected TWAP = (1500 * 100 + 2500 * 100) / 200 = 2000
        assertEq(twap, 2000 * 1e8, "TWAP calculation incorrect");
    }

    function testInvalidRounds() public {
        // Set up rounds with some invalid data
        oracle.setRoundData(1, 1000 * 1e8, 100, 100, 1);
        oracle.setRoundData(2, -1, 200, 200, 2); // Invalid price
        oracle.setRoundData(3, 3000 * 1e8, 300, 300, 3);

        vm.expectRevert(bytes("Invalid price data"));
        address(oracle).getTWAP(3);
    }

    function testDifferentDecimals() public {
        // Create new oracle with 6 decimals
        MockChainlinkOracle oracle6 = new MockChainlinkOracle(6);

        // Set up rounds with 6 decimal prices
        oracle6.setRoundData(1, 1000 * 1e6, 100, 100, 1);
        oracle6.setRoundData(2, 2000 * 1e6, 200, 200, 2);

        uint256 twap = address(oracle6).getTWAP(2);
        // Should convert 6 decimals to 8 decimals
        assertEq(twap, 1500 * 1e8, "TWAP should handle different decimals");
    }

    function testZeroRounds() public {
        // Test with zero rounds
        vm.expectRevert("Rounds must be > 0");
        address(oracle).getTWAP(0);
    }

    function testTimeWeightedCalculation() public {
        // Set up rounds with different time intervals
        // Round 1: Price = 1000 at t=100
        oracle.setRoundData(1, 1000 * 1e8, 100, 100, 1);
        // Round 2: Price = 2000 at t=300 (longer interval)
        oracle.setRoundData(2, 2000 * 1e8, 300, 300, 2);
        // Round 3: Price = 3000 at t=400 (shorter interval)
        oracle.setRoundData(3, 3000 * 1e8, 400, 400, 3);

        uint256 twap = address(oracle).getTWAP(3);

        // Expected TWAP = (1500 * 200 + 2500 * 100) / 300 = 1833.33...
        // With 8 decimals precision
        assertApproxEqAbs(
            twap,
            1833 * 1e8,
            1e8,
            "Time-weighted calculation incorrect"
        );
    }
}
