pragma solidity ^0.6.0;

import {SafeMath} from '@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol';
import {ERC20} from '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol';
import {WhitelistedRole} from '@openzeppelin/contracts-ethereum-package/contracts/access/roles/WhitelistedRole.sol';
import {IHonestSavings} from './interfaces/IHonestSavings.sol';
import {IHonestBonus} from './interfaces/IHonestBonus.sol';
import {IAssetPriceIntegration} from './integrations/IAssetPriceIntegration.sol';

contract HonestBonus is IHonestBonus, WhitelistedRole {

    using SafeMath for uint;

    address private _savings;
    address private _priceIntegration;

    mapping(address => uint) _bonuses;
    uint _totalBonuses;

    function initialize(address _priceIntegrationContract) external onlyWhitelistAdmin {
        setPriceIntegration(_priceIntegrationContract);
    }

    function setPriceIntegration(address _contract) public onlyWhitelistAdmin {
        require(_contract != address(0), 'address must be valid');
        _priceIntegration = _contract;
    }

    function getPriceIntegration() external view returns (address) {
        return _priceIntegration;
    }

    function hasBonus(address asset, uint fee) external view returns (bool) {
        require(_priceIntegration != address(0), 'price integration not initialized');
        uint value = IAssetPriceIntegration(_priceIntegration).getPrice(asset);
        return value > fee.add(1e18);
    }

    function calculateBonus(address _bAsset, uint _amount, uint _fee) external view returns (uint) {
        require(_priceIntegration != address(0), 'price integration not initialized');
        uint value = IAssetPriceIntegration(_priceIntegration).getPrice(_bAsset);
        if (value <= uint(1e18)) {
            return 0;
        }
        uint gap = value.mod(uint(1e18));
        if (gap > _fee) {
            return _amount.mul(gap.sub(_fee)).div(_getAmountScale(_bAsset));
        } else {
            return 0;
        }
    }

    function calculateBonuses(address[] calldata _bAssets, uint[] calldata _amounts, uint _fee)
    external view returns (uint) {
        require(_priceIntegration != address(0), 'price integration not initialized');
        uint[] memory values = IAssetPriceIntegration(_priceIntegration).getPrices(_bAssets);
        uint totalValue;
        for(uint i = 0; i < _bAssets.length; ++i) {
            if (values[i] <= uint(1e18)) {
                continue;
            }
            uint gap = values[i].mod(uint(1e18));
            if (gap > _fee) {
                totalValue = totalValue.add(_amounts[i].mul(gap.sub(_fee)).div(_getAmountScale(_bAssets[i])));
            }
        }
        return totalValue;
    }

    function bonusOf(address _account) external view returns (uint) {
        return _bonuses[_account];
    }

    function totalBonuses() external view returns (uint) {
        return _totalBonuses;
    }

    function addBonus(address _account, uint _bonus) external {
        require(_account != address(0), 'account must be valid');

        _bonuses[_account] = _bonuses[_account].add(_bonus);
        _totalBonuses = _totalBonuses.add(_bonus);
    }

    function subtractBonus(address _account, uint _bonus) external {
        require(_account != address(0), 'account must be valid');
        require(_bonus > 0, 'bonus must greater than 0');

        _bonuses[_account] = _bonuses[_account].sub(_bonus);
        _totalBonuses = _totalBonuses.sub(_bonus);
    }

    function _getAmountScale(address _token) internal view returns (uint) {
        return uint(10) ** uint(ERC20(_token).decimals());
    }
}