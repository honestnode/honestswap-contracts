pragma solidity ^0.5.0;

import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {ERC20Detailed} from '@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {WhitelistedRole} from '@openzeppelin/contracts/access/roles/WhitelistedRole.sol';
import {IHonestSavings} from '../interfaces/IHonestSavings.sol';
import {IHonestBonus} from '../interfaces/IHonestBonus.sol';
import {IAssetPriceIntegration} from '../integrations/IAssetPriceIntegration.sol';

contract HonestBonus is IHonestBonus, WhitelistedRole {

    using Address for address;
    using SafeMath for uint256;

    address private _savings;
    address private _priceIntegration;

    mapping(address => uint256) _bonuses;
    uint256 _totalBonuses;

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

    function hasBonus(address asset, uint256 fee) external view returns (bool) {
        require(_priceIntegration != address(0), 'price integration not initialized');
        uint256 value = IAssetPriceIntegration(_priceIntegration).getPrice(asset);
        return value > fee.add(1e18);
    }

    function calculateBonus(address _bAsset, uint256 _amount, uint256 _fee) external view returns (uint256) {
        require(_priceIntegration != address(0), 'price integration not initialized');
        uint256 value = IAssetPriceIntegration(_priceIntegration).getPrice(_bAsset);
        if (value <= uint256(1e18)) {
            return 0;
        }
        uint256 gap = value.mod(uint256(1e18));
        if (gap > _fee) {
            return _amount.mul(gap.sub(_fee)).div(_getAmountScale(_bAsset));
        } else {
            return 0;
        }
    }

    function calculateBonuses(address[] calldata _bAssets, uint256[] calldata _amounts, uint256 _fee)
    external view returns (uint256) {
        require(_priceIntegration != address(0), 'price integration not initialized');
        uint256[] memory values = IAssetPriceIntegration(_priceIntegration).getPrices(_bAssets);
        uint256 totalValue;
        for(uint256 i = 0; i < _bAssets.length; ++i) {
            if (values[i] <= uint256(1e18)) {
                continue;
            }
            uint256 gap = values[i].mod(uint256(1e18));
            if (gap > _fee) {
                totalValue = totalValue.add(_amounts[i].mul(gap.sub(_fee)).div(_getAmountScale(_bAssets[i])));
            }
        }
        return totalValue;
    }

    function bonusOf(address _account) external view returns (uint256) {
        return _bonuses[_account];
    }

    function totalBonuses() external view returns (uint256) {
        return _totalBonuses;
    }

    function addBonus(address _account, uint256 _bonus) external {
        require(_account != address(0), 'account must be valid');

        _bonuses[_account] = _bonuses[_account].add(_bonus);
        _totalBonuses = _totalBonuses.add(_bonus);
    }

    function subtractBonus(address _account, uint256 _bonus) external {
        require(_account != address(0), 'account must be valid');
        require(_bonus > 0, 'bonus must greater than 0');

        _bonuses[_account] = _bonuses[_account].sub(_bonus);
        _totalBonuses = _totalBonuses.sub(_bonus);
    }

    function _getAmountScale(address _token) internal view returns (uint256) {
        return uint256(10) ** uint256(ERC20Detailed(_token).decimals());
    }
}