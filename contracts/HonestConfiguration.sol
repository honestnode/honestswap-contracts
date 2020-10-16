// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;

import {EnumerableSet} from '@openzeppelin/contracts-ethereum-package/contracts/utils/EnumerableSet.sol';
import {AbstractHonestContract} from "./AbstractHonestContract.sol";
import {IHonestConfiguration} from "./interfaces/IHonestConfiguration.sol";

contract HonestConfiguration is IHonestConfiguration, AbstractHonestContract {

    using EnumerableSet for EnumerableSet.AddressSet;

    address private _honestAsset;

    EnumerableSet.AddressSet private _basketAssets;

    mapping(address => bool) private _basketAssetStates;

    mapping(address => address) _basketInvestments;

    uint private _activeBasketAssetsLength;

    uint private _swapFeeRate;

    uint private _redeemFeeRate;


    function initialize(address owner, address asset, address[] calldata bAssets, address[] calldata bAssetInvestments, uint swapFeeRate, uint redeemFeeRate) external initializer() {
        require(owner != address(0), 'HonestConfiguration.initialize: owner address must be valid');
        require(asset != address(0), 'HonestConfiguration.initialize: asset must be valid');
        require(bAssets.length > 0, 'HonestConfiguration.initialize: basket assets length must be greater than 0');
        require(bAssets.length == bAssetInvestments.length, 'HonestConfiguration.initialize: mismatch basket assets and investments length');

        super.initialize(owner);
        _honestAsset = asset;
        for (uint i; i < bAssets.length; ++i) {
            require(bAssets[i] != address(0), 'HonestConfiguration.initialize: basket asset must be valid');
            require(bAssetInvestments[i] != address(0), 'HonestConfiguration.initialize: basket asset investment integration must be valid');

            _basketAssets.add(bAssets[i]);
            _basketAssetStates[bAssets[i]] = true;
            _basketInvestments[bAssets[i]] = bAssetInvestments[i];
            ++_activeBasketAssetsLength;
        }
        _swapFeeRate = swapFeeRate;
        _redeemFeeRate = redeemFeeRate;
    }

    function honestAsset() external override view returns (address) {
        return _honestAsset;
    }

    function basketAssets() external override view returns (address[] memory, bool[] memory) {
        address[] memory assets = new address[](_basketAssets.length());
        bool[] memory states = new bool[](_basketAssets.length());
        for (uint i; i < _basketAssets.length(); ++i) {
            assets[i] = _basketAssets.at(i);
            states[i] = _basketAssetStates[assets[i]];
        }
        return (assets, states);
    }

    function activeBasketAssets() external override view returns (address[] memory) {
        address[] memory assets = new address[](_activeBasketAssetsLength);
        if (_activeBasketAssetsLength == 0) {
            return assets;
        }
        uint j;
        for (uint i; i < _basketAssets.length(); ++i) {
            if (_basketAssetStates[_basketAssets.at(i)]) {
                assets[j] = _basketAssets.at(i);
                ++j;
            }
        }
        return assets;
    }

    function basketAssetInvestmentIntegration(address asset) external override view returns (address) {
        require(_basketAssets.contains(asset), 'HonestConfiguration.basketAssetPriceIntegration: invalid basket asset');
        require(_basketAssetStates[asset], 'HonestConfiguration.basketAssetPriceIntegration: basket asset is not active');

        return _basketInvestments[asset];
    }

    function swapFeeRate() external override view returns (uint) {
        return _swapFeeRate;
    }

    function redeemFeeRate() external override view returns (uint) {
        return _redeemFeeRate;
    }

    function setHonestAsset(address asset) external override onlyGovernor {
        require(asset != address(0), 'HonestConfiguration.setHonestAsset: asset must be valid');
        _honestAsset = asset;
    }

    function addBasketAsset(address asset, address bAssetInvestment) external override onlyGovernor {
        require(asset != address(0), 'HonestConfiguration.addBasketAsset: basket asset must be valid');
        require(bAssetInvestment != address(0), 'HonestConfiguration.addBasketAsset: basket asset investment integration must be valid');

        if (!_basketAssets.contains(asset)) {
            _basketAssets.add(asset);
            _basketAssetStates[asset] = true;
            _basketInvestments[asset] = bAssetInvestment;
            ++_activeBasketAssetsLength;
        }
    }

    function removeBasketAsset(address asset) external override onlyGovernor {
        require(asset != address(0), 'HonestConfiguration.removeBasketAsset: basket asset must be valid');

        if (_basketAssets.contains(asset)) {
            _basketAssets.remove(asset);
            if (_basketAssetStates[asset]) {
                --_activeBasketAssetsLength;
            }
            delete _basketAssetStates[asset];
            delete _basketInvestments[asset];
        }
    }

    function activateBasketAsset(address asset) external override onlyGovernor {
        require(asset != address(0), 'HonestConfiguration.activateBasketAsset: basket asset must be valid');

        if (_basketAssets.contains(asset) && !_basketAssetStates[asset]) {
            _basketAssetStates[asset] = true;
            ++_activeBasketAssetsLength;
        }
    }

    function deactivateBasketAsset(address asset) external override onlyGovernor {
        require(asset != address(0), 'HonestConfiguration.deactivateBasketAsset: basket asset must be valid');

        if (_basketAssets.contains(asset) && _basketAssetStates[asset]) {
            _basketAssetStates[asset] = false;
            --_activeBasketAssetsLength;
        }
    }

    function setSwapFeeRate(uint feeRate) external override onlyGovernor {
        _swapFeeRate = feeRate;
    }

    function setRedeemFeeRate(uint feeRate) external override onlyGovernor {
        _redeemFeeRate = feeRate;
    }
}