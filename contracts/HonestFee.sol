// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;

import {SafeMath} from '@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol';
import {IERC20} from '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol';
import {IHonestFee} from "./interfaces/IHonestFee.sol";
import {IHonestConfiguration} from "./interfaces/IHonestConfiguration.sol";
import {AbstractHonestContract} from "./AbstractHonestContract.sol";

contract HonestFee is IHonestFee, AbstractHonestContract {

    using SafeERC20 for IERC20;
    using SafeMath for uint;

    address private _honestConfiguration;

    function initialize(address honestConfiguration) external initializer() {
        require(honestConfiguration != address(0), 'HonestFee.initialize: honestConfiguration address must be valid');

        super.initialize();
        _honestConfiguration = honestConfiguration;
    }

    function totalFee() public override view returns (uint) {
        address honestAsset = _honestAsset();
        return IERC20(honestAsset).balanceOf(address(this));
    }

    function reward(address account, uint amount) external override onlySavings returns (uint) {
        require(account != address(0), 'HonestFee.reward: account must be valid');
        require(amount <= totalFee(), 'HonestFee.reward: insufficient fee');

        address honestAsset = _honestAsset();
        if (amount > 0) {
            IERC20(honestAsset).safeTransfer(account, amount);
        }
        return amount;
    }

    function _honestAsset() internal view returns (address) {
        return IHonestConfiguration(_honestConfiguration).honestAsset();
    }
}