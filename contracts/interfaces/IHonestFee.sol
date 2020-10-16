// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;

interface IHonestFee {

    function totalFee() external view returns (uint);

    function claimableRewards() external view returns (uint);

    function reservedRewards() external view returns (uint);

    function distributeClaimableRewards(address account, uint price) external returns (uint);

    function distributeReservedRewards(address account) external;
}