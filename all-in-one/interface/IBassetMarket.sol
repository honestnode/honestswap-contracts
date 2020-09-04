pragma solidity 0.5.16;

interface IBassetMarket {

    function getBassetPrice(address _bAsset) external view
    returns (uint256 price, uint8 decimals);

    function getBassetsPrice(address[] _bAssets) external view
    returns (uint256[] prices, uint8[] decimals);

//    function setBassetPrice(address _bAsset, uint256 _price) external;
//    function setBassetPrices(address[] _bAssets, uint256[] _prices) external;
}
