pragma solidity ^0.6.0;

interface IHonestFee {

    function initialize(address _hAssetContract) external;

    function swapFeeRate() external view returns (uint);

    function redeemFeeRate() external view returns (uint);

    function setSwapFeeRate(uint _newFeeRate) external;

    function setRedeemFeeRate(uint _newFeeRate) external;

    function totalFee() external view returns (uint);

    function reward(address _account, uint _amount) external returns (uint);
}