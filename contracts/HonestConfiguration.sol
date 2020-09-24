// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;

import {EnumerableSet} from '@openzeppelin/contracts-ethereum-package/contracts/utils/EnumerableSet.sol';
import {AbstractHonestContract} from "./AbstractHonestContract.sol";
import {IAssetPriceIntegration} from './integrations/IAssetPriceIntegration.sol';
import {IHonestConfiguration} from "./interfaces/IHonestConfiguration.sol";

contract HonestConfiguration is IHonestConfiguration, AbstractHonestContract {

    using EnumerableSet for EnumerableSet.AddressSet;


    address private _honestAsset;

    EnumerableSet.AddressSet private _basketAssets;

    mapping(address => bool) private _basketAssetStates;

    mapping(address => IHonestConfiguration.Integrations) _basketIntegrations;

    uint private _activeBasketAssetsLength;

    uint private _swapFeeRate;

    uint private _redeemFeeRate;


    function initialize(address asset, address[] calldata bAssets, IAssetPriceIntegration.FeedsTarget[] calldata bAssetPriceTargets, address[] calldata bAssetPrices, address[] calldata bAssetInvestments, uint swapFeeRate, uint redeemFeeRate) external override initializer() {
        require(asset != address(0), 'HonestConfiguration.initialize: asset must be valid');
        require(bAssets.length == bAssetPriceTargets.length, 'HonestConfiguration.initialize: mismatch basket assets and price targets length');
        require(bAssets.length == bAssetPrices.length, 'HonestConfiguration.initialize: mismatch basket assets and prices length');
        require(bAssets.length == bAssetInvestments.length, 'HonestConfiguration.initialize: mismatch basket assets and investments length');

        _honestAsset = asset;
        for(uint i; i < bAssets.length; ++i) {
            require(bAssets[i] != address(0), 'HonestConfiguration.initialize: basket asset must be valid');
            require(bAssetPrices[i] != address(0), 'HonestConfiguration.initialize: basket asset price integration must be valid');
            require(bAssetInvestments[i] != address(0), 'HonestConfiguration.initialize: basket asset investment integration must be valid');

            _basketAssets.add(bAssets[i]);
            _basketAssetStates[bAssets[i]] = true;
            _basketIntegrations[bAssets[i]] = IHonestConfiguration.Integrations(bAssetPriceTargets[i], bAssetPrices[i], bAssetInvestments[i]);
            ++_activeBasketAssetsLength;
        }
        _swapFeeRate = swapFeeRate;
        _redeemFeeRate = redeemFeeRate;
    }

    function honestAsset() external override view returns (address) {
        return _honestAsset;
    }

    function setHonestAsset(address asset) external override onlyGovernor {
        require(asset != address(0), 'HonestConfiguration.setHonestAsset: asset must be valid');
        _honestAsset = asset;
    }

    function basketAssets() external override view returns (address[] memory, bool[] memory) {
        address[] memory assets = new address[](_basketAssets.length());
        bool[] memory states = new bool[](_basketAssets.length());
        for(uint i; i < _basketAssets.length(); ++i) {
            assets[i] = _basketAssets.at(i);
            states[i] = _basketAssetStates[assets[i]];
        }
        return (assets, states);
    }

    function activeBasketAssets() external override view returns (address[] memory) {
        address[] memory assets = new address[](_activeBasketAssetsLength);
        uint j;
        for(uint i; i < _basketAssets.length(); ++i) {
            if (_basketAssetStates[_basketAssets.at(i)]) {
                assets[j] = _basketAssets.at(i);
                ++j;
            }
        }
        return assets;
    }

    function addBasketAsset(address asset, IAssetPriceIntegration.FeedsTarget bAssetPriceTarget, address bAssetPrice, address bAssetInvestment) external override onlyGovernor {
        require(asset != address(0), 'HonestConfiguration.addBasketAsset: basket asset must be valid');
        require(bAssetPrice != address(0), 'HonestConfiguration.addBasketAsset: basket asset price integration must be valid');
        require(bAssetInvestment != address(0), 'HonestConfiguration.addBasketAsset: basket asset investment integration must be valid');

        if (_basketAssets.contains(asset)) {
            _basketAssets.add(asset);
            _basketAssetStates[asset] = true;
            _basketIntegrations[asset] = IHonestConfiguration.Integrations(bAssetPriceTarget, bAssetPrice, bAssetInvestment);
            ++_activeBasketAssetsLength;
        }
    }

    function removeBasketAsset(address asset) external override onlyGovernor {
        require(asset != address(0), 'HonestConfiguration.removeBasketAsset: basket asset must be valid');

        if (_basketAssets.contains(asset)) {
            _basketAssets.remove(asset);
            delete _basketAssetStates[asset];
            delete _basketIntegrations[asset];
            --_activeBasketAssetsLength;
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
            delete _basketAssetStates[asset];
            --_activeBasketAssetsLength;
        }
    }

    function swapFeeRate() external override returns (uint) {
        return _swapFeeRate;
    }

    function setSwapFeeRate(uint feeRate) external override onlyGovernor {
        _swapFeeRate = feeRate;
    }

    function redeemFeeRate() external override returns (uint) {
        return _redeemFeeRate;
    }

    function setRedeemFeeRate(uint feeRate) external override onlyGovernor {
        _redeemFeeRate = feeRate;
    }
}