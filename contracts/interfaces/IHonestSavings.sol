// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;

interface IHonestSavings {

    function honestConfiguration() external view returns (address);

    function investmentIntegration() external view returns (address);

    function weightOf(address account) external view returns (uint);

    function totalWeight() external view returns (uint);

    function shareOf(address account) external view returns (uint);

    function totalShare() external view returns (uint);

    function totalValue() external view returns (uint);

    function sharePrice() external view returns (uint);

    function deposit(address account, address vault, address[] calldata assets, uint[] calldata amounts) external;

    function withdraw(address account, address vault, uint weight) external;

    function apy() external view returns (int256);

    function swap(address _account, address[] calldata _bAssets, uint[] calldata _borrows, address[] calldata _sAssets, uint[] calldata _supplies)
    external;

    function setHonestConfiguration(address honestConfiguration_) external;

    function setInvestmentIntegration(address investmentIntegration_) external;
}
