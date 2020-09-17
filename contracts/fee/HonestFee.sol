pragma solidity ^0.5.0;

import {WhitelistAdminRole} from '@openzeppelin/contracts/access/roles/WhitelistAdminRole.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {IHonestFee} from "../interfaces/IHonestFee.sol";

contract HonestFee is IHonestFee, WhitelistAdminRole {

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address private _hAsset;
    uint256 private _swapFeeRate = uint256(1e15);
    uint256 private _redeemFeeRate = uint256(1e15);

    function initialize(address _hAssetContract) external onlyWhitelistAdmin {
        require(_hAssetContract != address(0), 'address must be valid');
        _hAsset = _hAssetContract;
    }

    function setSwapFeeRate(uint256 _newFeeRate) external onlyWhitelistAdmin {
        _swapFeeRate = _newFeeRate;
    }

    function setRedeemFeeRate(uint256 _newFeeRate) external onlyWhitelistAdmin {
        _redeemFeeRate = _newFeeRate;
    }

    function swapFeeRate() external view returns (uint256) {
        return _swapFeeRate;
    }

    function redeemFeeRate() external view returns (uint256) {
        return _redeemFeeRate;
    }

    function totalFee() external view returns (uint256) {
        return _totalFee();
    }

    function reward(address _account, uint256 _percentage) external returns (uint256) {
        require(_percentage <= uint256(1e18), 'insufficient balance');

        uint256 amount = _percentage.mul(_totalFee()).div(uint256(1e18));
        if (amount > 0) {
            IERC20(_hAsset).safeTransfer(_account, amount);
        }
        return amount;
    }

    function _totalFee() internal view returns (uint256) {
        return IERC20(_hAsset).balanceOf(address(this));
    }
}