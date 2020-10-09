// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;

interface IHonestAssetManager {

    function honestConfiguration() external view returns (address);

    function honestVault() external view returns (address);

    function mint(address[] calldata bAssets, uint[] calldata amounts) external;

    function mintTo(address[] calldata bAssets, uint[] calldata amounts, address recipient) external;

    function redeemProportionally(uint amount) external;

    function redeemProportionallyTo(uint amount, address recipient) external;

    function redeemManually(address[] calldata bAssets, uint[] calldata amounts) external;

    function redeemManuallyTo(address[] calldata bAssets, uint[] calldata amounts, address recipient) external;

    function swap(address from, address to, uint amount) external;

    function swapTo(address from, address to, uint amount, address recipient) external;

    function deposit(address to, uint amount) external returns (uint[] memory);

    function withdraw(address to, address[] calldata assets, uint[] calldata amounts, uint interests) external;

    function setHonestConfiguration(address honestConfiguration_) external;

    function setHonestVault(address honestVault_) external;
}