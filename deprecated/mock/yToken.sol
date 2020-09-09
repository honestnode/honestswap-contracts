pragma solidity ^0.5.0;

interface yToken {
    function deposit(uint256 _amount) external;

    function withdraw(uint256 _shares) external;

    function balance() external view returns (uint256);
}