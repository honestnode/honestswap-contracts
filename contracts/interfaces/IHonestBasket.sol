pragma solidity ^0.5.0;

interface IHonestBasket {
    /** @dev Basket balance value of each bAsset */
    function getBasketBalance(address[] calldata bAssets) external view returns (uint256[] memory);

    /** @dev Basket all bAsset info */
    function getBasket() external view returns (address[] memory bAssets, uint8[] memory statuses);

    /** @dev query bAsset info */
    function getBAssetStatus(address _bAsset) external returns (bool, uint8);
    /** @dev query bAssets info */
    function getBAssetsStatus(address[] calldata _bAssets) external returns (bool, uint8[] memory);

    /** @dev Setters for Gov to update Basket composition */
    function addBAsset(address _bAsset, uint8 _status) external returns (bool);

}
