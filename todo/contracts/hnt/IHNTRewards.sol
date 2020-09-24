pragma solidity ^0.6.0;

interface IHNTRewards {

    function setToken(address _token) external;

    function totalSavings() external view returns (uint);

    function totalRewards() external view returns (uint);

    function savingsOf(address _account) external view returns (uint);

    function rewardsOf(address _account) external view returns (uint);

    function sharesOf(address _account) external view returns (uint);

    function deposit(uint _amount) external returns (bool);

    function redeem(uint _amount) external returns (bool);
}