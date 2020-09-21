pragma solidity ^0.5.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ERC20Detailed} from '@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';

/**
 * @dev Standard ERC20 contract functions, support 18 decimals ERC20 token
 *
 * use this library add `using StandardERC20 for ERC20Detailed;` statement to your contract
 */
library StandardERC20 {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint8 private constant _standardDecimals = 18;

    function standardBalanceOf(ERC20Detailed token, address account) internal view returns (uint256) {
        uint256 balance = token.balanceOf(account);
        return standardize(token, balance);
    }

    function standardApprove(ERC20Detailed token, address to, uint256 standardAmount) internal {
        return IERC20(token).safeApprove(to, resume(token, standardAmount));
    }

    function standardTransfer(ERC20Detailed token, address to, uint256 standardAmount) internal {
        return IERC20(token).safeTransfer(to, resume(token, standardAmount));
    }

    function standardize(ERC20Detailed token, uint256 value) internal view returns (uint256) {
        uint8 decimals = token.decimals();
        require(decimals <= _standardDecimals, 'illegal decimals');
        if (decimals == _standardDecimals) {
            return value;
        }
        return value.mul(uint256(10) ** uint256(_standardDecimals - decimals));
    }

    function resume(ERC20Detailed token, uint256 value) internal view returns (uint256) {
        uint8 decimals = token.decimals();
        require(decimals <= _standardDecimals, 'illegal decimals');
        if (decimals == _standardDecimals) {
            return value;
        }
        return value.div(uint256(10) ** uint256(_standardDecimals - decimals));
    }
}