// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {AggregatorV3Interface} from "../interfaces/AggregatorV3Interface.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

library ChainlinkUtils {
    using Math for uint256;

    function getPriceWithDecimals(
        address chainlinkOracle,
        uint8 decimals
    ) public view returns (uint256) {
        AggregatorV3Interface oracle = AggregatorV3Interface(chainlinkOracle);
        uint8 oracleDecimals = oracle.decimals();
        int256 latestAnswer = oracle.latestAnswer();
        require(latestAnswer > 0, "Invalid price data");
        if (oracleDecimals == decimals) {
            return uint256(latestAnswer);
        }
        if (oracleDecimals > decimals) {
            return uint256(latestAnswer) / (10 ** (oracleDecimals - decimals));
        }

        return uint256(latestAnswer) * (10 ** (decimals - oracleDecimals));
    }
}
