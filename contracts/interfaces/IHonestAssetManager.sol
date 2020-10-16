// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;

interface IHonestAssetManager {

    function honestConfiguration() external view returns (address);

    function honestVault() external view returns (address);

    function mint(address[] calldata bAssets, uint[] calldata amounts) external;

    function redeemProportionally(uint amount) external;

    function redeemManually(address[] calldata assets, uint[] calldata amounts) external;

    function swap(address from, address to, uint amount) external;

    function deposit(uint amount) external;

    function withdraw(uint weight) external;

    function setHonestConfiguration(address honestConfiguration_) external;

    function setHonestVault(address honestVault_) external;
}