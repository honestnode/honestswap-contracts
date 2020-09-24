pragma solidity ^0.6.0;

import {AbstractHonestContract} from "./AbstractHonestContract.sol";
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


    function initialize(address asset, address[] bAssets, IHonestConfiguration.Integrations[] integrations, uint swapFeeRate, uint redeemFeeRate)
    external initializer {
        require(asset != address(0), 'HonestConfiguration.initialize: asset must be valid');
        require(bAssets.length == integrations.length, 'HonestConfiguration.initialize: mismatch basket assets and integrations length');

        _honestAsset = asset;
        for(uint i; i < bAssets.length; ++i) {
            require(bAssets[i] != address(0), 'HonestConfiguration.initialize: basket asset must be valid');
            require(integrations[i].price != address(0), 'HonestConfiguration.initialize: basket asset price integration must be valid');
            require(integrations[i].investment != address(0), 'HonestConfiguration.initialize: basket asset investment integration must be valid');

            _basketAssets.add(bAssets[i]);
            _basketAssetStates[bAssets[i]] = true;
            _basketIntegrations[bAssets[i]] = integrations[i];
            ++_activeBasketAssetsLength;
        }
        _swapFeeRate = swapFeeRate;
        _redeemFeeRate = redeemFeeRate;
    }

    function honestAsset() external view returns (address) {
        return _honestAsset;
    }

    function setHonestAsset(address asset) external onlyGovernor {
        require(asset != address(0), 'HonestConfiguration.setHonestAsset: asset must be valid');
        _honestAsset = asset;
    }

    function basketAssets() external view returns (address[] memory, bool[] memory) {
        address[] memory assets = new address[](_basketAssets.length());
        bool[] memory states = new bool[](_basketAssets.length());
        for(uint i; i < _basketAssets.length(); ++i) {
            assets[i] = _basketAssets.at(i);
            states[i] = _basketAssetStates[bAssets[i]];
        }
        return (assets, states);
    }

    function activeBasketAssets() external view returns (address[] memory) {
        address[] memory assets = new address[](_activeBasketAssetsLength);
        uint j;
        for(uint i; i < _basketAssets.length(); ++i) {
            if (_basketAssetStates[_basketAssets[i]]) {
                assets[j] = _basketAssets[i];
                ++j;
            }
        }
        return assets;
    }

    function addBasketAsset(address asset, Integrations integration) external onlyGovernor {
        require(asset != address(0), 'HonestConfiguration.addBasketAsset: basket asset must be valid');
        require(integration.price != address(0), 'HonestConfiguration.addBasketAsset: basket asset price integration must be valid');
        require(integration.investment != address(0), 'HonestConfiguration.addBasketAsset: basket asset investment integration must be valid');

        if (_basketAssets.contains(asset)) {
            _basketAssets.add(asset);
            _basketAssetStates[asset] = true;
            _basketIntegrations[asset] = integration;
            ++_activeBasketAssetsLength;
        }
    }

    function removeBasketAsset(address asset) external onlyGovernor {
        require(asset != address(0), 'HonestConfiguration.removeBasketAsset: basket asset must be valid');

        if (_basketAssets.contains(asset)) {
            _basketAssets.remove(asset);
            delete _basketAssetStates[asset];
            delete _basketIntegrations[asset];
            --_activeBasketAssetsLength;
        }
    }

    function activateBasketAsset(address asset) external onlyGovernor {
        require(asset != address(0), 'HonestConfiguration.activateBasketAsset: basket asset must be valid');

        if (_basketAssets.contains(asset) && !_basketAssetStates[asset]) {
            _basketAssetStates[asset] = true;
            ++_activeBasketAssetsLength;
        }
    }

    function deactivateBasketAsset(address asset) external onlyGovernor {
        require(asset != address(0), 'HonestConfiguration.deactivateBasketAsset: basket asset must be valid');

        if (_basketAssets.contains(asset) && _basketAssetStates[asset]) {
            delete _basketAssetStates[asset];
            --_activeBasketAssetsLength;
        }
    }

    function swapFeeRate() external returns (uint) {
        return _swapFeeRate;
    }

    function setSwapFeeRate(uint feeRate) external onlyGovernor {
        _swapFeeRate = feeRate;
    }

    function redeemFeeRate() external returns (uint) {
        return _redeemFeeRate;
    }

    function setRedeemFeeRate(uint feeRate) external onlyGovernor {
        _redeemFeeRate = feeRate;
    }
}