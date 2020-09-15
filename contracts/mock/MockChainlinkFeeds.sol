pragma solidity ^0.5.0;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.5/interfaces/AggregatorV3Interface.sol";

contract MockETH2USDFeeds is AggregatorV3Interface {

    function decimals() external view returns (uint8) {
        return 8;
    }

    function description() external view returns (string memory) {
        return 'ETH / USD';
    }

    function version() external view returns (uint256) {
        return 2;
    }

    function getRoundData(uint80 _roundId)
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (1, 0, 0, 0, 1);
    }

    // $400
    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (36893488147419107971, 40000000000, 1600149669, 1600149669, 36893488147419107971);
    }
}

contract MockDAI2USDFeeds is AggregatorV3Interface {

    function decimals() external view returns (uint8) {
        return 8;
    }

    function description() external view returns (string memory) {
        return 'DAI / USD';
    }

    function version() external view returns (uint256) {
        return 2;
    }

    function getRoundData(uint80 _roundId)
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (1, 0, 0, 0, 1);
    }

    // $1.014
    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (18446744073709553239, 101400000, 1598371337, 1598371337, 18446744073709553239);
    }
}

contract MockTUSD2ETHFeeds is AggregatorV3Interface {

    function decimals() external view returns (uint8) {
        return 18;
    }

    function description() external view returns (string memory) {
        return 'TUSD / ETH';
    }

    function version() external view returns (uint256) {
        return 2;
    }

    function getRoundData(uint80 _roundId)
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (1, 0, 0, 0, 1);
    }

    // $1.003
    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (36893488147419106358, 2507500000000000, 1600150918, 1600150918, 36893488147419106358);
    }
}

contract MockUSDC2ETHFeeds is AggregatorV3Interface {

    function decimals() external view returns (uint8) {
        return 18;
    }

    function description() external view returns (string memory) {
        return 'USDC / ETH';
    }

    function version() external view returns (uint256) {
        return 2;
    }

    function getRoundData(uint80 _roundId)
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (1, 0, 0, 0, 1);
    }

    // $0.96
    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (36893488147419106551, 2400000000000000, 1600150272, 1600150272, 36893488147419106551);
    }
}

contract MockUSDT2ETHFeeds is AggregatorV3Interface {

    function decimals() external view returns (uint8) {
        return 18;
    }

    function description() external view returns (string memory) {
        return 'USDT / ETH';
    }

    function version() external view returns (uint256) {
        return 2;
    }

    function getRoundData(uint80 _roundId)
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (1, 0, 0, 0, 1);
    }

    // $1.016
    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (36893488147419106363, 2540000000000000, 1600141918, 1600141918, 36893488147419106363);
    }
}