pragma solidity ^0.5.0;

interface IHonestFee {

    function initialize(address _hAssetContract) external;

    function swapFeeRate() external view returns (uint256);

    function redeemFeeRate() external view returns (uint256);

    function setSwapFeeRate(uint256 _newFeeRate) external;

    function setRedeemFeeRate(uint256 _newFeeRate) external;

    function totalFee() external view returns (uint256);

    function reward(address _account, uint256 _amount) external returns (uint256);
}