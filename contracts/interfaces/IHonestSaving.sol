pragma solidity ^0.5.0;

interface IHonestSaving {

    function deposit(uint256 _amount) external returns (uint256);

    function withdraw(uint256 _amount) external returns (uint256);

    function balanceOf(address _account) external view returns (uint256);

    function sharesOf(address _account) external view returns (uint256);

    function totalBalance() external view returns (uint256);

    function totalShares() external view returns (uint256);

    function netValue() external view returns (uint256);

    function apy() external view returns (uint256);

    function borrow(address[] _bAssets, uint256[] _amounts) external returns (uint256);

    function supply(address[] _bAssets, uint256[] _amounts) external returns (uint256);
}