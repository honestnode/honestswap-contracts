// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;

interface IAssetPriceIntegration {

    enum FeedsTarget {USD, ETH}

    function honestConfiguration() external view returns (address);

    function ethPriceFeeds() external view returns (address);

    function getPrice(address asset) external view returns (uint);

    function getPrices(address[] calldata assets) external view returns (uint[] memory);

    function setHonestConfiguration(address configuration) external;

    function setEthPriceFeeds(address feeds) external;
}