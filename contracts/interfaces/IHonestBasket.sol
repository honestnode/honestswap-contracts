pragma solidity ^0.5.0;

interface IHonestBasket {
    /** @dev Basket balance value of each bAsset */
    function getBasketBalance(address[] calldata bAssets) external view returns (uint256[] memory balance);

    /** @dev Basket all bAsset info */
    function getBasket() external view returns (address[] memory bAssets, uint8[] memory status);

    /** @dev query bAsset info */
    function getBAssetStatus(address _bAsset) external returns (uint8 status);
    /** @dev query bAssets info */
    function getBAssetsStatus(address[] calldata _bAssets) external returns (uint8[] memory status);

    /** @dev Setters for Gov to update Basket composition */
    function addBAsset(address _bAsset, uint8 status) external returns (bool result);

}
