// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;

import {SafeMath} from '@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol';
import {IERC20} from '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol';
import {IHonestFee} from "./interfaces/IHonestFee.sol";
import {IHonestConfiguration} from "./interfaces/IHonestConfiguration.sol";
import {AbstractHonestContract} from "./AbstractHonestContract.sol";

contract HonestFee is IHonestFee, AbstractHonestContract {

    using SafeERC20 for IERC20;
    using SafeMath for uint;

    address private _honestConfiguration;
    uint private _honestAssetRewardsPercentage;

    function initialize(address honestConfiguration) external initializer() {
        require(honestConfiguration != address(0), 'HonestFee.initialize: honestConfiguration address must be valid');

        super.initialize();
        _honestConfiguration = honestConfiguration;
    }

    function totalFee() public override view returns (uint) {
        address honestAsset = _honestAsset();
        return IERC20(honestAsset).balanceOf(address(this));
    }

    function honestAssetRewardsPercentage() public override view returns (uint) {
        return _honestAssetRewardsPercentage;
    }

    function honestAssetRewards() public override view returns (uint) {
        return totalFee().mul(_honestAssetRewardsPercentage).div(uint(1e18));
    }

    function distributeHonestAssetRewards(address account, uint price) external override returns (uint) {
        require(account != address(0), 'HonestFee.distributeHonestAssetRewards: account must be valid');

        uint rewards = honestAssetRewards();
        if (rewards > 0) {
            address honestAsset = _honestAsset();
            IERC20(honestAsset).safeTransfer(account, rewards);
        }

        return honestAssetRewards().mul(uint(1e18)).div(price);
    }

    function reward(address account, uint amount) external override onlySavings returns (uint) {
        require(account != address(0), 'HonestFee.reward: account must be valid');
        require(amount <= totalFee(), 'HonestFee.reward: insufficient fee');

        address honestAsset = _honestAsset();
        if (amount > 0) {
            IERC20(honestAsset).safeTransfer(account, amount);
        }
        return amount;
    }

    function _honestAsset() internal view returns (address) {
        return IHonestConfiguration(_honestConfiguration).honestAsset();
    }

    function setHonestAssetRewardsPercentage(uint percentage) external override onlyGovernor {
        require(percentage < uint(1e18), 'HonestFee.setHonestAssetRewardsPercentage: percentage should be less than 1');

        _honestAssetRewardsPercentage = percentage;
    }
}