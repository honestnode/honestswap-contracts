// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;

interface IHonestVault {

    function honestConfiguration() external view returns (address);

    function investmentIntegration() external view returns (address);

    function honestFee() external view returns (address);

    function deposit(address account, uint amount) external returns (uint);

    function withdraw(address account, uint weight) external returns (uint);

    function balances() external view returns (address[] memory, uint[] memory, uint);

    function weightOf(address account) external view returns (uint);

    function shareOf(address account) external view returns (uint);

    function shareValue() external view returns (uint);

    function distributeProportionally(address account, uint amount) external;

    function distributeManually(address account, address[] calldata assets, uint[] calldata amounts) external;

    function setHonestConfiguration(address honestConfiguration_) external;

    function setInvestmentIntegration(address investmentIntegration_) external;

    function setHonestFee(address honestFee_) external;
}