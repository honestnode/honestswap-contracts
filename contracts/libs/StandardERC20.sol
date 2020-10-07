// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';

/**
 * @dev Standard ERC20 contract functions, support 18 decimals ERC20 token
 *
 * use this library add `using StandardERC20 for ERC20;` statement to your contract
 */
library StandardERC20 {

    using SafeERC20 for IERC20;
    using SafeMath for uint;

    uint8 private constant _standardDecimals = 18;

    function standardBalanceOf(ERC20 token, address account) internal view returns (uint) {
        uint balance = token.balanceOf(account);
        return standardize(token, balance);
    }

    function standardApprove(ERC20 token, address to, uint standardAmount) internal {
        return IERC20(token).safeApprove(to, resume(token, standardAmount));
    }

    function standardTransfer(ERC20 token, address to, uint standardAmount) internal {
        return IERC20(token).safeTransfer(to, resume(token, standardAmount));
    }

    function standardTransferFrom(ERC20 token, address from, address to, uint standardAmount) internal {
        return IERC20(token).safeTransferFrom(from, to, resume(token, standardAmount));
    }

    function standardize(ERC20 token, uint value) internal view returns (uint) {
        uint8 decimals = token.decimals();
        require(decimals <= _standardDecimals, 'illegal decimals');
        if (decimals == _standardDecimals) {
            return value;
        }
        return value.mul(uint(10) ** uint(_standardDecimals - decimals));
    }

    function resume(ERC20 token, uint value) internal view returns (uint) {
        uint8 decimals = token.decimals();
        require(decimals <= _standardDecimals, 'illegal decimals');
        if (decimals == _standardDecimals) {
            return value;
        }
        return value.div(uint(10) ** uint(_standardDecimals - decimals));
    }
}