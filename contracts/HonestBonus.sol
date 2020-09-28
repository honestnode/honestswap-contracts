pragma solidity ^0.6.0;

import {SafeMath} from '@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {IHonestConfiguration} from './interfaces/IHonestConfiguration.sol';
import {IHonestSavings} from './interfaces/IHonestSavings.sol';
import {IHonestBonus} from './interfaces/IHonestBonus.sol';
import {IAssetPriceIntegration} from './integrations/IAssetPriceIntegration.sol';
import {AbstractHonestContract} from "./AbstractHonestContract.sol";

contract HonestBonus is IHonestBonus, AbstractHonestContract {

    using SafeMath for uint;

    address private _priceIntegration;

    mapping(address => uint) _bonuses;
    uint _totalBonus;

    function initialize(address priceIntegration) external initializer() {
        require(priceIntegration != address(0), 'HonestBonus.initialize: priceIntegration address must be valid');

        super.initialize();
        _priceIntegration = priceIntegration;
    }

    function priceIntegration() external override view returns (address) {
        return _priceIntegration;
    }

    function hasBonus(address asset, uint feeRate) external override view returns (bool) {
        require(asset != address(0), 'HonestBonus.hasBonus: asset must be valid');

        uint value = IAssetPriceIntegration(_priceIntegration).getPrice(asset);
        return value > feeRate.add(1e18);
    }

    function calculateBonus(address asset, uint amount, uint feeRate) public override view returns (uint) {
        require(asset != address(0), 'HonestBonus.calculateBonus: asset must be valid');
        if (amount == 0) {
            return 0;
        }
        uint value = IAssetPriceIntegration(_priceIntegration).getPrice(asset);
        uint threshold = feeRate.add(uint(1e18));
        if (value <= threshold) {
            return 0;
        }
        return amount.mul(value.sub(threshold)).div(_getAmountScale(asset));
    }

    function calculateBonuses(address[] calldata assets, uint[] calldata amounts, uint feeRate)
    external override view returns (uint) {
        uint[] memory values = IAssetPriceIntegration(_priceIntegration).getPrices(assets);
        uint totalValue;
        for (uint i; i < assets.length; ++i) {
            totalValue.add(calculateBonus(assets[i], amounts[i], feeRate));
        }
        return totalValue;
    }

    function bonusOf(address account) external override view returns (uint) {
        return _bonuses[account];
    }

    function totalBonus() external override view returns (uint) {
        return _totalBonus;
    }

    function setPriceIntegration(address priceIntegration) external override onlyGovernor {
        require(priceIntegration != address(0), 'HonestBonus.initialize: priceIntegration address must be valid');
        _priceIntegration = priceIntegration;
    }

    function addBonus(address account, uint bonus) external override onlyAssetManager {
        require(account != address(0), 'HonestBonus.addBonus: account must be valid');

        _bonuses[account] = _bonuses[account].add(bonus);
        _totalBonus = _totalBonus.add(bonus);
    }

    function subtractBonus(address account, uint bonus) external override onlyAssetManager {
        require(account != address(0), 'HonestBonus.subtractBonus: account must be valid');
        require(bonus <= _bonuses[account], 'HonestBonus.subtractBonus: insufficient bonus');

        _bonuses[account] = _bonuses[account].sub(bonus);
        _totalBonus = _totalBonus.sub(bonus);
    }

    function _getAmountScale(address asset) internal view returns (uint) {
        return uint(10) ** uint(ERC20(asset).decimals());
    }
}