pragma solidity ^0.6.0;

import {IERC20} from '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol';
import {SafeMath} from '@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol';
import {OwnableUpgradeSafe} from '@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol';
import {IHNTRewards} from "./IHNTRewards.sol";

contract HNTRewords is IHNTRewards, OwnableUpgradeSafe {

    using SafeERC20 for IERC20;
    using SafeMath for uint;

    uint public sharesRatio = 1e4;
    uint public lastRedeemTime = 0;
    address public token;

    mapping (address => uint) private _savings;
    uint private _totalSavings;

    constructor(address _token) public {
        require(_token != address(0), "Address must be valid");
        token = _token;
    }

    function setToken(address _token) external onlyOwner {
        require(_token != address(0), "Address must be valid");
        token = _token;
    }

    function totalSavings() external view returns (uint) {
        return _totalSavings;
    }

    function totalRewards() external view returns (uint) {
        return _totalRewards();
    }

    function savingsOf(address _account) external view returns (uint) {
        require(_account != address(0), "Address must be valid");
        return _savings[_account];
    }

    function rewardsOf(address _account) external view returns (uint) {
        require(_account != address(0), "Address must be valid");
        return _rewardsOf(_account);
    }

    function sharesOf(address _account) external view returns (uint) {
        require(_account != address(0), "Address must be valid");
        if (_totalSavings == 0) {
            return 0;
        }
        uint savings = _savings[_msgSender()];
        return savings.mul(sharesRatio).div(_totalSavings);
    }

    function deposit(uint _amount) external returns (bool) {
        require(_amount > 0, "deposit must be greater than 0");
        _totalSavings = _totalSavings.add(_amount);
        _savings[_msgSender()] = _savings[_msgSender()].add(_amount);
        return true;
    }

    function redeem(uint _amount) external returns (bool) {
        require(_amount > 0, "redeem must be greater than 0");
        uint savings = _savings[_msgSender()];
        require(_amount <= savings, "insufficient savings");

        IERC20(token).safeTransfer(_msgSender(), _amount);
        return true;
    }

    function _totalRewards() internal view returns (uint) {
        // TODO:
        return 0;
    }

    function _rewardsOf(address _account) internal view returns (uint) {
        return _sharesOf(_account).mul(_totalRewards()).div(sharesRatio);
    }

    function _sharesOf(address _account) internal view returns (uint) {
        if (_totalSavings == 0) {
            return 0;
        }
        uint savings = _savings[_account];
        return savings.mul(sharesRatio).div(_totalSavings);
    }

    function _deliveryRewards() internal {

    }
}