pragma solidity ^0.5.0;

interface IHonestFee {

    function swapFeeRate() external view returns (uint256);

    function redeemFeeRate() external view returns (uint256);

    function chargeSwapFee(address _account, uint256 _amount) external returns (uint256);

    function chargeRedeemFee(address _account, uint256 _amount) external returns (uint256);

    function totalFee() external view returns (uint256);

    function reward(address _account, uint256 _amount) external view returns (uint256);
}