pragma solidity ^0.5.0;

import {SafeMath}  from "@openzeppelin/contracts/math/SafeMath.sol";
import {SafeERC20}  from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {IERC20}     from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {HonestMath} from "./HonestMath.sol";

/**
 * @title   HAssetHelpers
 * @author  HonestSwap. Ltd.
 * @notice  Helper functions to facilitate minting and redemption from off chain
 * @dev     VERSION: 1.0
 */
library HAssetHelpers {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function transferTokens(
        address _sender,
        address _recipient,
        address _basset,
        bool _erc20TransferFeeCharged,
        uint256 _qty
    )
    internal
    returns (uint256 receivedQty)
    {
        receivedQty = _qty;
        if (_erc20TransferFeeCharged) {
            uint256 balBefore = IERC20(_basset).balanceOf(_recipient);
            IERC20(_basset).safeTransferFrom(_sender, _recipient, _qty);
            uint256 balAfter = IERC20(_basset).balanceOf(_recipient);
            receivedQty = HonestMath.min(_qty, balAfter.sub(balBefore));
        } else {
            IERC20(_basset).safeTransferFrom(_sender, _recipient, _qty);
        }
    }

    function safeInfiniteApprove(address _asset, address _spender)
    internal
    {
        IERC20(_asset).safeApprove(_spender, 0);
        IERC20(_asset).safeApprove(_spender, uint256(- 1));
    }
}
