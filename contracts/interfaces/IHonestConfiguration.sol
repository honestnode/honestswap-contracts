// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;

import {IAssetPriceIntegration} from '../integrations/IAssetPriceIntegration.sol';

interface IHonestConfiguration {

    function honestAsset() external view returns (address);

    function basketAssets() external view returns (address[] memory, bool[] memory);

    function activeBasketAssets() external view returns (address[] memory);

    function basketAssetInvestmentIntegration(address asset) external view returns (address);

    function swapFeeRate() external view returns (uint);

    function redeemFeeRate() external view returns (uint);

    function claimableRewardsPercentage() external view returns (uint);

    function addBasketAsset(address asset, address bAssetInvestment) external;

    function removeBasketAsset(address asset) external;

    function activateBasketAsset(address asset) external;

    function deactivateBasketAsset(address asset) external;

    function setSwapFeeRate(uint feeRate) external;

    function setRedeemFeeRate(uint feeRate) external;

    function setClaimableRewardsPercentage(uint percentage) external;
}