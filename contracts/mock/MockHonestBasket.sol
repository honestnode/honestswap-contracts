pragma solidity ^0.5.0;

import {IHonestBasket} from '../interfaces/IHonestBasket.sol';

contract MockHonestBasket is IHonestBasket {

    address[] private _bAssets;
    uint8[] private _statues;
    uint256[] private _balances;

    /** @dev Balance value of the bAsset */
    function getBalance(address _bAsset) external view returns (uint256 balance) {
        return 0;
    }

    /** @dev Balance of each bAsset */
    function getBAssetsBalance(address[] calldata _bAssets) external view returns (uint256 sumBalance, uint256[] memory balances) {
        return (0, new uint256[](_bAssets.length));
    }

    /** @dev Balance of all the bAssets in basket */
    function getBasketAllBalance() external view returns (uint256 sumBalance, address[] memory allBAssets, uint256[] memory balances) {
        return (0, _bAssets, _balances);
    }

    /** @dev Basket all bAsset info */
    function getBasket() external view returns (address[] memory bAssets, uint8[] memory statuses) {
        return (_bAssets, _statues);
    }

    /** @dev query bAsset info */
    function getBAssetStatus(address _bAsset) external returns (bool, uint8) {
        return (false, 0);
    }

    /** @dev query bAssets info */
    function getBAssetsStatus(address[] calldata _bAssets) external returns (bool, uint8[] memory) {
        return (false, _statues);
    }

    /** @dev Setters for Gov to update Basket composition */
    function addBAsset(address _bAsset, uint8 _status) external returns (uint8 index) {
        return 0;
    }

    function updateBAssetStatus(address _bAsset, uint8 _newStatus) external returns (uint8 index) {
        return 0;
    }

    function swapBAssets(address _integration, uint256 _totalAmounts, address[] calldata _expectAssets)
    external returns (uint256[] memory) {
        return new uint256[](_expectAssets.length);
    }

    function distributeHAssets(address _account, address[] calldata _bAssets, uint256[] calldata _amounts, uint256 _interests)
    external {

    }
}