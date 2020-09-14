pragma solidity ^0.5.0;

import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {IHonestBonus} from '../interfaces/IHonestBonus.sol';

contract HonestBonus is IHonestBonus {

    using Address for address;
    using SafeMath for uint256;

    mapping(address => uint256) _bonuses;
    uint256 _totalBonuses;

    function calculateBonus(address _bAsset) external view returns (uint256) {
        // TODO: integrate ChainLink
        return 0;
    }

    function bonusOf(address _account) external view returns (uint256) {
        return _bonuses[_account];
    }

    function totalBonuses() external view returns (uint256) {
        return _totalBonuses;
    }

    function addBonus(address _account, uint256 _bonus) external {
        require(_account != address(0), 'account must be valid');
        require(_bonus > 0, 'bonus must greater than 0');

        _bonuses[_account] = _bonuses[_account].add(_bonus);
        _totalBonuses = _totalBonuses.add(_bonus);
    }

    function subtractBonus(address _account, uint256 _bonus) external {
        require(_account != address(0), 'account must be valid');
        require(_bonus > 0, 'bonus must greater than 0');

        _bonuses[_account] = _bonuses[_account].sub(_bonus);
        _totalBonuses = _totalBonuses.sub(_bonus);
    }


}