pragma solidity ^0.5.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IHonestFee} from "../interfaces/IHonestFee.sol";
import {HonestMath} from "../util/HonestMath.sol";

contract MockHonestFee is IHonestFee {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address private _hAsset;
    uint256 private _swapFeeRate;
    uint256 private _redeemFeeRate;

    function initialize(address _hAssetContract) external {
        require(_hAssetContract != address(0), 'address must be valid');
        _hAsset = _hAssetContract;
    }

    function swapFeeRate() external view returns (uint256){
        return _swapFeeRate;
    }

    function redeemFeeRate() external view returns (uint256){
        return _redeemFeeRate;
    }

    function setSwapFeeRate(uint256 _newFeeRate) external {
        _swapFeeRate = _newFeeRate;
    }

    function setRedeemFeeRate(uint256 _newFeeRate) external {
        _redeemFeeRate = _newFeeRate;
    }

    function totalFee() public view returns (uint256){
        return IERC20(_hAsset).balanceOf(address(this));
    }

    function reward(address _account, uint256 _percentage) external returns (uint256){
        uint256 amount = _percentage.mul(totalFee()).div(uint256(1e18));
        IERC20(_hAsset).safeTransfer(_account, amount);
        return amount;
    }
}
