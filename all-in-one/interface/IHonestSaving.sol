pragma solidity 0.5.16;

/**
 * @title   IHonestSaving
 * @author  HonestSwap. Ltd.
 */
interface IHonestSaving {

    function deposit(uint256 _amount) external returns (uint256 creditsIssued);

    function redeem(uint256 _amount) external returns (uint256 hAssetReturned);

    function querySavingBalance() external returns (uint256 hAssetBalance);

    function queryHUsdSavingApy() external returns (uint256 apy);
}
