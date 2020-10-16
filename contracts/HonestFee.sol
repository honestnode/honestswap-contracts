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
    uint private _claimableRewards;
    uint private _reservedRewards;

    function initialize(address honestConfiguration_) external initializer() {
        require(honestConfiguration_ != address(0), 'HonestFee.initialize: honestConfiguration address must be valid');

        super.initialize();
        _honestConfiguration = honestConfiguration_;
    }

    function totalFee() public override view returns (uint) {
        address honestAsset = _honestAsset();
        return IERC20(honestAsset).balanceOf(address(this));
    }

    function _claimableRewardsPercentage() internal view returns (uint) {
        return IHonestConfiguration(_honestConfiguration).claimableRewardsPercentage();
    }

    function claimableRewards() public override view returns (uint) {
        return _availableRewards().mul(_claimableRewardsPercentage()).div(uint(1e18)).add(_claimableRewards);
    }

    function reservedRewards() public override view returns (uint) {
        uint percentage = uint(1e18).sub(_claimableRewardsPercentage());
        return _availableRewards().mul(percentage).div(uint(1e18)).add(_reservedRewards);
    }

    function distributeClaimableRewards(address account, uint price) external override onlyVault returns (uint) {
        require(account != address(0), 'HonestFee.distributeHonestAssetRewards: account must be valid');

        uint rewards = claimableRewards();
        if (rewards > 0) {
            IERC20(_honestAsset()).safeTransfer(account, rewards);
            _reservedRewards = _reservedRewards.add(totalFee());
            _claimableRewards = 0;
        }

        return rewards.mul(uint(1e18)).div(price);
    }

    function distributeReservedRewards(address account) external override onlyOwner {
        require(account != address(0), 'HonestFee.distributeReservedRewards: account must be valid');

        uint rewards = reservedRewards();
        if (rewards > 0) {
            IERC20(_honestAsset()).safeTransfer(account, rewards);
            _claimableRewards = _claimableRewards.add(totalFee());
            _reservedRewards = 0;
        }
    }

    function _honestAsset() internal view returns (address) {
        return IHonestConfiguration(_honestConfiguration).honestAsset();
    }

    function _availableRewards() internal view returns (uint) {
        return totalFee().sub(_claimableRewards).sub(_reservedRewards);
    }
}