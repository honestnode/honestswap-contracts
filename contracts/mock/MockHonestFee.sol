pragma solidity ^0.5.0;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IHonestFee} from "../interfaces/IHonestFee.sol";
import {HonestMath} from "../util/HonestMath.sol";

contract MockHonestFee is IHonestFee {

    using SafeMath for uint256;
    using HonestMath for uint256;

    address private _hAsset;
    uint256 private _swapFeeRate;
    uint256 private _redeemFeeRate;


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

    function totalFee() external view returns (uint256){
        return 100;
    }

    function reward(address _account, uint256 _percentage) external returns (uint256){

        //        uint256 amount = _percentage.mul(_totalFee()).div(uint256(1e18));
        //        IERC20(_hAsset).safeTransfer(_account, amount);

        return 100;
    }
}
