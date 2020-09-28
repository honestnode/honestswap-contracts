// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;

interface IHonestBonus {

    function priceIntegration() external view returns (address);

    function hasBonus(address asset, uint feeRate) external view returns (bool);

    function calculateBonus(address asset, uint amount, uint feeRate) external view returns (uint);

    function calculateBonuses(address[] calldata assets, uint[] calldata amounts, uint feeRate) external view returns (uint);

    function bonusOf(address account) external view returns (uint);

    function totalBonus() external view returns (uint);

    function setPriceIntegration(address priceIntegration) external;

    function addBonus(address account, uint bonus) external;

    function subtractBonus(address _account, uint _bonus) external;
}