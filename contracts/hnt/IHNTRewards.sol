pragma solidity ^0.5.0;

interface IHNTRewards {

    function setToken(address _token) external;

    function totalSavings() external view returns (uint256);

    function totalRewards() external view returns (uint256);

    function savingsOf(address _account) external view returns (uint256);

    function rewardsOf(address _account) external view returns (uint256);

    function sharesOf(address _account) external view returns (uint256);

    function deposit(uint256 _amount) external returns (bool);

    function redeem(uint256 _amount) external returns (bool);
}