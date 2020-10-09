// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;

interface IHonestFee {

    function totalFee() external view returns (uint);

    function honestAssetRewardsPercentage() external view returns (uint);

    function honestAssetRewards() external view returns (uint);

    function distributeHonestAssetRewards(address account, uint price) external returns (uint);

    function reward(address account, uint amount) external returns (uint);

    function setHonestAssetRewardsPercentage(uint percentage) external;
}