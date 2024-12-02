// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {AggregatorV3Interface} from "../interfaces/AggregatorV3Interface.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

library ChainlinkTWAP {
    using Math for uint256;

    /// @notice Calculates TWAP for a given oracle over specified number of rounds
    /// @param chainlinkOracle Address of the Chainlink price feed
    /// @param numRounds Number of rounds to look back
    /// @return twap Time-weighted average price with 8 decimals
    function getTWAP(
        address chainlinkOracle,
        uint80 numRounds
    ) public view returns (uint256) {
        require(numRounds > 0, "Rounds must be > 0");

        AggregatorV3Interface oracle = AggregatorV3Interface(chainlinkOracle);
        uint8 oracleDecimals = oracle.decimals();

        // Get current round
        (uint80 currentRoundId, , , , ) = oracle.latestRoundData();

        uint256 cumulativePrice = 0;
        uint256 timeWeight = 0;
        uint80 startRound = currentRoundId - numRounds;

        // Iterate through rounds to calculate weighted sum
        for (uint80 i = startRound; i < currentRoundId; i++) {
            (, int256 price1, uint256 timestamp1, , ) = oracle.getRoundData(i);
            (, int256 price2, uint256 timestamp2, , ) = oracle.getRoundData(
                i + 1
            );

            // Revert on invalid rounds
            require(price1 > 0 && price2 > 0, "Invalid price data");

            // Calculate time-weighted price for this interval
            uint256 timeDelta = timestamp2 - timestamp1;

            cumulativePrice += timeDelta.mulDiv(uint256(price1 + price2), 2);
            timeWeight += timeDelta;
        }

        require(timeWeight > 0, "No valid price data");

        // Calculate TWAP with proper decimal handling
        uint256 rawTWAP = Math.mulDiv(cumulativePrice, 1, timeWeight);

        // Convert to 8 decimals
        if (oracleDecimals > 8) {
            return rawTWAP / (10 ** (oracleDecimals - 8));
        } else if (oracleDecimals < 8) {
            return rawTWAP * (10 ** (8 - oracleDecimals));
        }

        return rawTWAP;
    }
}
