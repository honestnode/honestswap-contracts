pragma solidity ^0.6.0;

import {IERC20} from '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol';
import {SafeMath} from "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import {IHonestFee} from "../interfaces/IHonestFee.sol";

contract MockHonestFee is IHonestFee {

    using SafeERC20 for IERC20;
    using SafeMath for uint;

    address private _hAsset;
    uint private _swapFeeRate;
    uint private _redeemFeeRate;

    function initialize(address _hAssetContract) external {
        require(_hAssetContract != address(0), 'address must be valid');
        _hAsset = _hAssetContract;
    }

    function swapFeeRate() external view returns (uint){
        return _swapFeeRate;
    }

    function redeemFeeRate() external view returns (uint){
        return _redeemFeeRate;
    }

    function setSwapFeeRate(uint _newFeeRate) external {
        _swapFeeRate = _newFeeRate;
    }

    function setRedeemFeeRate(uint _newFeeRate) external {
        _redeemFeeRate = _newFeeRate;
    }

    function totalFee() public view returns (uint){
        return IERC20(_hAsset).balanceOf(address(this));
    }

    function reward(address _account, uint _amount) external returns (uint) {
        require(_amount <= totalFee(), 'insufficient fee');
        IERC20(_hAsset).safeTransfer(_account, _amount);
        return _amount;
    }
}
