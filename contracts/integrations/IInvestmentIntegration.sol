// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;

interface IInvestmentIntegration {

    function invest(address account, address asset, uint amount) external returns (uint);

    function collect(address account, address asset, uint credits) external returns (uint);

    function priceOf(address asset) external view returns (uint);

    function shareOf(address asset) external view returns (uint);

    function shares() external view returns (address[] memory, uint[] memory, uint, uint);

    function balanceOf(address asset) external view returns (uint);

    function balances() external view returns (address[] memory, uint[] memory, uint);

    function totalBalance() external view returns (uint);
}