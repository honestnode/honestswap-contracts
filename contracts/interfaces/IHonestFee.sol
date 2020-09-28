// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;

interface IHonestFee {

    function totalFee() external view returns (uint);

    function reward(address _account, uint _amount) external returns (uint);
}