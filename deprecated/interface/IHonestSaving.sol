pragma solidity 0.5.16;

import {HassetStructs} from "./HassetStructs.sol";

/**
 * @title   IHonestSaving
 * @author  HonestSwap. Ltd.
 */
contract IHonestSaving is HassetStructs {

    function deposit(uint256 _amount) external returns (uint256 depositAmount);

    function redeem(uint256 _amount) external returns (uint256 hAssetReturned);

    function querySavingBalance() external view returns (uint256 hAssetBalance);

    function queryHUsdSavingApy() external view returns (uint256 apy, uint256 apyTimestamp);
}
