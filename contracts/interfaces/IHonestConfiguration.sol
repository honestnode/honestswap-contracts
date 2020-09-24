// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;

import {IAssetPriceIntegration} from '../integrations/IAssetPriceIntegration.sol';

interface IHonestConfiguration {

    struct Integrations {
        IAssetPriceIntegration.FeedsTarget priceTarget;
        address price;
        address investment;
    }

    function initialize(address asset, address[] calldata bAssets, IAssetPriceIntegration.FeedsTarget[] calldata bAssetPriceTargets, address[] calldata bAssetPrices, address[] calldata bAssetInvestments, uint swapFeeRate, uint redeemFeeRate) external;

    function honestAsset() external view returns (address);

    function setHonestAsset(address asset) external;

    function basketAssets() external view returns (address[] memory, bool[] memory);

    function activeBasketAssets() external view returns (address[] memory);

    function addBasketAsset(address asset, IAssetPriceIntegration.FeedsTarget bAssetPriceTarget, address bAssetPrice, address bAssetInvestment) external;

    function removeBasketAsset(address asset) external;

    function activateBasketAsset(address asset) external;

    function deactivateBasketAsset(address asset) external;

    function swapFeeRate() external returns (uint);

    function setSwapFeeRate(uint feeRate) external;

    function redeemFeeRate() external returns (uint);

    function setRedeemFeeRate(uint feeRate) external;
}