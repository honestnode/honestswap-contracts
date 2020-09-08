pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

interface IBassetMarket {

    function getBassetPrice(address _bAsset) external view
    returns (uint256 price, uint256 decimals);

    function getBassetsPrice(address[] calldata _bAssets) external view
    returns (uint256[] memory prices, uint256[] memory decimals);

//    function setBassetPrice(address _bAsset, uint256 _price) external;
//    function setBassetPrices(address[] _bAssets, uint256[] _prices) external;
}
