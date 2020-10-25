// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;

interface IHonestBonus {

    function hasBonus(address asset) external view returns (bool);

    function calculateMintBonus(address[] calldata assets, uint[] calldata amounts) external view returns (uint);
}