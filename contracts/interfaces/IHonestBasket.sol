pragma solidity ^0.5.0;

interface IHonestBasket {
    /** @dev Basket balance value of each bAsset */
    function getBasketBalance() external view returns (address[] memory bAssets, uint256[] balance);

    /** @dev Basket all bAsset info */
    function getBasket() external view returns (address[] memory bAssets, uint8[] memory status);

    /** @dev query bAsset info */
    function getBAsset(address _bAsset) external returns (address addr, uint8 status);
    /** @dev query bAssets info */
    function getBAssets(address[] calldata _bAssets) external returns (address[] memory bAssets, uint8[] memory status);

    /** @dev Setters for Gov to update Basket composition */
    function addBAsset(address _bAsset, uint8 status) external returns (uint8 index);

}
