pragma solidity ^0.5.0;


interface IHonestBasket {
    /** @dev Balance value of the bAsset */
//    function getBalance(address _bAsset) external view returns (uint256 balance);

    /** @dev Balance of each bAsset */
    function getBAssetsBalance(address[] calldata _bAssets) external view returns (uint256 sumBalance, uint256[] memory balances);

    /** @dev Balance of all the bAssets in basket */
    function getBasketAllBalance() external view returns (uint256 sumBalance, address[] memory allBAssets, uint256[] memory balances);

    /** @dev Basket all bAsset info */
    function getBasket() external view returns (address[] memory bAssets, uint8[] memory statuses);

    /** @dev query bAsset info */
    function getBAssetStatus(address _bAsset) external returns (bool, uint8);

    /** @dev query bAssets info */
    function getBAssetsStatus(address[] calldata _bAssets) external returns (bool, uint8[] memory);

    function swap(address _input, address _output, uint256 _quantity, address _recipient)
    external returns (uint256 outputQuantity);

    function getSwapOutput(address _input, address _output, uint256 _quantity)
    external returns (bool, string memory, uint256 outputQuantity);

    function swapBAssets(address _integration, uint256 _totalAmounts, address[] calldata _expectAssets)
    external returns (uint256[] memory);

    function distributeHAssets(address _account, address[] calldata _bAssets, uint256[] calldata _amounts, uint256 _interests)
    external;

    /** @dev Setters for Gov to update Basket composition */
    function addBAsset(address _bAsset, uint8 _status) external returns (uint8 index);

    function updateBAssetStatus(address _bAsset, uint8 _newStatus) external returns (uint8 index);
}
