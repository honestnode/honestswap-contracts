pragma solidity ^0.5.0;

interface IHonestFee {

    function swapFeeRate() external view returns (uint256);

    function redeemFeeRate() external view returns (uint256);

    function totalFee() external view returns (uint256);

    function reward(address _account, uint256 _percentage) external returns (uint256);
}