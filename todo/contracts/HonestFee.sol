pragma solidity ^0.6.0;

import {WhitelistAdminRole} from '@openzeppelin/contracts-ethereum-package/contracts/access/roles/WhitelistAdminRole.sol';
import {SafeMath} from '@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol';
import {IERC20} from '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol';
import {IHonestFee} from "./interfaces/IHonestFee.sol";

contract HonestFee is IHonestFee, WhitelistAdminRole {

    using SafeERC20 for IERC20;
    using SafeMath for uint;

    address private _hAsset;
    uint private _swapFeeRate = uint(1e15);
    uint private _redeemFeeRate = uint(1e15);

    function initialize(address _hAssetContract) external onlyWhitelistAdmin {
        require(_hAssetContract != address(0), 'address must be valid');
        _hAsset = _hAssetContract;
    }

    function setSwapFeeRate(uint _newFeeRate) external onlyWhitelistAdmin {
        _swapFeeRate = _newFeeRate;
    }

    function setRedeemFeeRate(uint _newFeeRate) external onlyWhitelistAdmin {
        _redeemFeeRate = _newFeeRate;
    }

    function swapFeeRate() external view returns (uint) {
        return _swapFeeRate;
    }

    function redeemFeeRate() external view returns (uint) {
        return _redeemFeeRate;
    }

    function totalFee() public view returns (uint) {
        return _totalFee();
    }

    function reward(address _account, uint _amount) external returns (uint) {
        require(_amount <= totalFee(), 'insufficient fee');

        if (_amount > 0) {
            IERC20(_hAsset).safeTransfer(_account, _amount);
        }
        return _amount;
    }

    function _totalFee() internal view returns (uint) {
        return IERC20(_hAsset).balanceOf(address(this));
    }
}