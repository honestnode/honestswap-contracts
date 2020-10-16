// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;
//
//import {SafeMath} from '@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol';
//import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
//import {IHonestConfiguration} from './interfaces/IHonestConfiguration.sol';
//import {IHonestSavings} from './interfaces/IHonestSavings.sol';
//import {IHonestBonus} from './interfaces/IHonestBonus.sol';
//import {IAssetPriceIntegration} from './integrations/IAssetPriceIntegration.sol';
//import {AbstractHonestContract} from "./AbstractHonestContract.sol";
//
//contract HonestBonus is IHonestBonus, AbstractHonestContract {
//
//    using SafeMath for uint;
//
//    address private _priceIntegration;
//
//    mapping(address => uint) _bonuses;
//    mapping(address => uint) _bonusPrices;
//    mapping(address => uint) _bonusShares;
//    uint _totalBonus;
//    uint _totalShare;
//
//    function initialize(address priceIntegration_) external initializer() {
//        require(priceIntegration_ != address(0), 'HonestBonus.initialize: priceIntegration address must be valid');
//
//        super.initialize();
//        _priceIntegration = priceIntegration_;
//    }
//
//    function priceIntegration() external override view returns (address) {
//        return _priceIntegration;
//    }
//
//    function hasBonus(address asset, uint feeRate) external override view returns (bool) {
//        require(asset != address(0), 'HonestBonus.hasBonus: asset must be valid');
//
//        uint value = IAssetPriceIntegration(_priceIntegration).getPrice(asset);
//        return value > feeRate.add(1e18);
//    }
//
//    function calculateBonus(address asset, uint amount, uint feeRate) public override view returns (uint) {
//        require(asset != address(0), 'HonestBonus.calculateBonus: asset must be valid');
//        if (amount == 0) {
//            return 0;
//        }
//        uint value = IAssetPriceIntegration(_priceIntegration).getPrice(asset);
//        uint threshold = feeRate.add(uint(1e18));
//        if (value <= threshold) {
//            return 0;
//        }
//        return amount.mul(value.sub(threshold)).div(_getAmountScale(asset));
//    }
//
//    function calculateBonuses(address[] calldata assets, uint[] calldata amounts, uint feeRate)
//    external override view returns (uint) {
//        uint totalValue;
//        for (uint i; i < assets.length; ++i) {
//            totalValue.add(calculateBonus(assets[i], amounts[i], feeRate));
//        }
//        return totalValue;
//    }
//
//    function bonusOf(address account) external override view returns (uint) {
//        return _bonuses[account];
//    }
//
//    function shareOf(address account) external override view returns (uint) {
//        return _bonusShares[account];
//    }
//
//    function totalBonus() external override view returns (uint) {
//        return _totalBonus;
//    }
//
//    function totalShare() external override view returns (uint) {
//        return _totalShare;
//    }
//
//    function addBonus(address account, uint bonus, uint price) external override onlyAssetManager {
//        require(account != address(0), 'HonestBonus.addBonus: account must be valid');
//        if (price == 0) {
//            return;
//        }
//
//        uint share = bonus.mul(uint(1e18)).div(price);
//
//        if (_bonuses[account] == 0) {
//            _bonuses[account] = bonus;
//            _bonusPrices[account] = price;
//            _bonusShares[account] = share;
//        } else {
//            _bonuses[account] = _bonuses[account].add(bonus);
//            _bonusShares[account] = _bonusShares[account].add(share);
//            _bonusPrices[account] = _bonuses[account].mul(uint(1e18)).div(_bonusShares[account]);
//        }
//        _totalBonus = _totalBonus.add(bonus);
//    }
//
//    function reward(address account, uint price) external override onlyAssetManager returns (uint) {
//        require(account != address(0), 'HonestBonus.subtractBonus: account must be valid');
//
//        if (price < _bonusPrices[account]) {
//            return 0;
//        }
//        uint amount = _bonusShares[account].mul(price.sub(_bonusPrices[account])).div(uint(1e18));
//        _bonusPrices[account] = price;
//        return amount;
//    }
//
//    function _getAmountScale(address asset) internal view returns (uint) {
//        return uint(10) ** uint(ERC20(asset).decimals());
//    }
//}