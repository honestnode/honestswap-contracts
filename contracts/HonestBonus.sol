// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;

import {SafeMath} from '@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol';
import {IHonestConfiguration} from './interfaces/IHonestConfiguration.sol';
import {IHonestBonus} from './interfaces/IHonestBonus.sol';
import {IHonestVault} from './interfaces/IHonestVault.sol';
import {AbstractHonestContract} from "./AbstractHonestContract.sol";

contract HonestBonus is IHonestBonus, AbstractHonestContract {

    using SafeMath for uint;

    address private _honestConfiguration;
    address private _honestVault;

    function initialize(address honestConfiguration_, address honestVault_) external initializer() {
        require(honestConfiguration_ != address(0), 'HonestBonus.initialize: honestConfiguration must be valid');
        require(honestVault_ != address(0), 'HonestBonus.initialize: honestVault must be valid');

        super.initialize();
        _honestConfiguration = honestConfiguration_;
        _honestVault = honestVault_;
    }

    function hasBonus(address asset) external override onlyAssetManager view returns (bool) {
        (, , uint totalBalance) = IHonestVault(_honestVault).balances();
        uint weight = _weight(asset, totalBalance);
        uint expectWeight = _expectWeight();
        return weight < expectWeight;
    }

    function calculateMintBonus(address[] calldata assets, uint[] calldata amounts) external override onlyAssetManager view returns (uint) {
        (, , uint totalBalance) = IHonestVault(_honestVault).balances();
        uint bonus;
        for (uint i; i < assets.length; ++i) {
            uint weight = _weight(assets[i], totalBalance);
            uint expectWeight = _expectWeight();
            if (weight < expectWeight) {
                bonus = bonus.add(amounts[i].mul(uint(1e18).sub(weight.mul(uint(1e18)).div(expectWeight))).div(uint(1e18)));
            }
        }
        return bonus;
    }

    function _weight(address asset, uint totalBalance) internal view returns (uint) {
        if (totalBalance == 0) {
            return 0;
        }
        uint balance = IHonestVault(_honestVault).balanceOf(asset);
        return balance.mul(uint(1e18)).div(totalBalance);
    }

    function _expectWeight() internal view returns (uint) {
        address[] memory assets = IHonestConfiguration(_honestConfiguration).activeBasketAssets();
        return uint(1e18).div(assets.length);
    }
}