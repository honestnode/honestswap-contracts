pragma solidity ^0.6.0;

interface IAssetPriceIntegration {

    enum FeedsTarget {USD, ETH}

    function initialize(FeedsTarget[] calldata _types, address[] calldata _assets, address[] calldata _feedsContracts) external;

    function register(FeedsTarget _type, address _asset, address _feedsContract) external;

    function deregister(FeedsTarget _type, address _asset) external;

    function getPrice(address _asset) external view returns (uint);

    function getPrices(address[] calldata _assets) external view returns (uint[] memory);
}