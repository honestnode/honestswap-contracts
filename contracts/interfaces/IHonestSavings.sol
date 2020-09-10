pragma solidity ^0.5.0;

interface IHonestSavings {

    function deposit(uint256 _amount) external returns (uint256);

    function withdraw(uint256 _amount) external returns (uint256);

    function savingsOf(address _account) external view returns (uint256);

    function sharesOf(address _account) external view returns (uint256);

    function totalSavings() external view returns (uint256);

    function totalShares() external view returns (uint256);

    function netValue() external view returns (uint256);

    function apy() external view returns (uint256);

    function borrow(address[] _bAssets, uint256[] _amounts) external returns (uint256);

    function supply(uint256 _amounts) external returns (uint256);
}