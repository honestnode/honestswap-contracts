pragma solidity ^0.5.0;

interface IHonestBasket {
    /** @dev Basket total balance value */
    function getBasketValue() external view returns (uint256 balance);

    /** @dev Basket all bAsset info */
    function getBasket() external view returns (address[] memory bAssets, uint8[] memory status, bool[] memory isTransferFeeCharged);

    /** @dev query bAsset info */
    function getBAsset(address _bAsset) external returns (address addr, uint8 status, bool isTransferFeeCharged);
    /** @dev query bAssets info */
    function getBAssets(address[] calldata _bAssets) external returns (address[] memory bAssets, uint8[] memory status, bool[] memory isTransferFeeCharged);

    /** @dev Setters for Gov to update Basket composition */
    function addBAsset(address _bAsset, address _integration, bool _isTransferFeeCharged) external returns (uint8 index);

    function setTransferFeesFlag(address _bAsset, bool _flag) external;

}
