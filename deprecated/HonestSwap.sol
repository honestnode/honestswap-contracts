pragma solidity 0.5.16;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Initializable} from "@openzeppelin/upgrades/contracts/Initializable.sol";
import {InitializablePausableModule} from "./common/InitializablePausableModule.sol";
import {InitializableReentrancyGuard} from "./common/InitializableReentrancyGuard.sol";

import {IHonestSwap} from "./interface/IHonestSwap.sol";
import {HassetStructs} from "./interface/HassetStructs.sol";
import {HonestMath} from "./util/HonestMath.sol";

contract HonestSwap is
Initializable,
IHonestSwap,
HassetStructs,
InitializablePausableModule,
InitializableReentrancyGuard {

    using SafeMath for uint256;
    using HonestMath for uint256;

    event SwapFeeChanged(uint256 fee);

    mapping(address => uint8) private bAssetsMap;
    address[] public integrations;
    uint256 private swapFee;// 0.1%
    uint256 private MAX_FEE;// 10%

    function initialize(
        address _nexus
    )
    external
    initializer
    {
        InitializablePausableModule._initialize(_nexus);
        InitializableReentrancyGuard._initialize();

        MAX_FEE = 1e7;
        swapFee = 1e5;
    }

    /***************************************
                SWAP (PUBLIC)
    ****************************************/

    /**
     * @dev Simply swaps one bAsset for another bAsset or this mAsset at a 1:1 ratio.
     * bAsset <> bAsset swaps will incur a small fee (swapFee()). Swap
     * is valid if it does not result in the input asset exceeding its maximum weight.
     * @param _input        bAsset to deposit
     * @param _output       Asset to receive - either a bAsset or mAsset(this)
     * @param _quantity     Units of input bAsset to swap
     * @param _recipient    Address to credit output asset
     * @return output       Units of output asset returned
     */
//    function swap(
//        address _input,
//        address _output,
//        uint256 _quantity,
//        address _recipient
//    )
//    external
//    nonReentrant
//    returns (uint256 outputQuantity)
//    {
//        require(_input != address(0) && _output != address(0), "Invalid swap asset addresses");
//        require(_input != _output, "Cannot swap the same asset");
//        require(_recipient != address(0), "Missing recipient address");
//        require(_quantity > 0, "Invalid quantity");
//
//        // 1. If the output is this mAsset, just mint
//        if (_output == address(this)) {
//            return _mintTo(_input, _quantity, _recipient);
//        }
//
//        // 2. Grab all relevant info from the Manager
//        (bool isValid, string memory reason, BassetDetails memory inputDetails, BassetDetails memory outputDetails) =
//        basketManager.prepareSwapBassets(_input, _output, false);
//        require(isValid, reason);
//
//        // 3. Deposit the input tokens
//        uint256 quantitySwappedIn = _depositTokens(_input, inputDetails.integrator, inputDetails.bAsset.isTransferFeeCharged, _quantity);
//        // 3.1. Update the input balance
//        basketManager.increaseVaultBalance(inputDetails.index, inputDetails.integrator, quantitySwappedIn);
//
//        // 4. Validate the swap
//        (bool swapValid, string memory swapValidityReason, uint256 swapOutput, bool applySwapFee) =
//        forgeValidator.validateSwap(totalSupply(), inputDetails.bAsset, outputDetails.bAsset, quantitySwappedIn);
//        require(swapValid, swapValidityReason);
//
//        // 5. Settle the swap
//        // 5.1. Decrease output bal
//        basketManager.decreaseVaultBalance(outputDetails.index, outputDetails.integrator, swapOutput);
//        // 5.2. Calc fee, if any
//        if (applySwapFee) {
//            swapOutput = _deductSwapFee(_output, swapOutput, swapFee);
//        }
//        // 5.3. Withdraw to recipient
//        IPlatformIntegration(outputDetails.integrator).withdraw(_recipient, _output, swapOutput, outputDetails.bAsset.isTransferFeeCharged);
//
//        output = swapOutput;
//
//        emit Swapped(msg.sender, _input, _output, swapOutput, _recipient);
//    }
//
//
//    /**
//     * @dev Determines both if a trade is valid, and the expected fee or output.
//     * Swap is valid if it does not result in the input asset exceeding its maximum weight.
//     * @param _input        bAsset to deposit
//     * @param _output       Asset to receive - bAsset or hAsset(this)
//     * @param _quantity     Units of input bAsset to swap
//     * @return valid        Bool to signify that swap is current valid
//     * @return reason       If swap is invalid, this is the reason
//     * @return output       Units of _output asset the trade would return
//     */
//    function getSwapOutput(
//        address _input,
//        address _output,
//        uint256 _quantity
//    )
//    external
//    view
//    returns (bool, string memory, uint256 output)
//    {
//        require(_input != address(0) && _output != address(0), "Invalid swap asset addresses");
//        require(_input != _output, "Cannot swap the same asset");
//
//        bool isMint = _output == address(this);
//        uint256 quantity = _quantity;
//
//        // 1. Get relevant asset data
//        (bool isValid, string memory reason, BassetDetails memory inputDetails, BassetDetails memory outputDetails) =
//        basketManager.prepareSwapBassets(_input, _output, isMint);
//        if (!isValid) {
//            return (false, reason, 0);
//        }
//
//        // 2. check if trade is valid
//        // 2.1. If output is hAsset(this), then calculate a simple mint
//        if (isMint) {
//            // Validate mint
//            (isValid, reason) = forgeValidator.validateMint(totalSupply(), inputDetails.bAsset, quantity);
//            if (!isValid) return (false, reason, 0);
//            // Simply cast the quantity to hAsset
//            output = quantity.mulRatioTruncate(inputDetails.bAsset.ratio);
//            return (true, "", output);
//        }
//        // 2.2. If a bAsset swap, calculate the validity, output and fee
//        else {
//            (bool swapValid, string memory swapValidityReason, uint256 swapOutput, bool applySwapFee) =
//            forgeValidator.validateSwap(totalSupply(), inputDetails.bAsset, outputDetails.bAsset, quantity);
//            if (!swapValid) {
//                return (false, swapValidityReason, 0);
//            }
//
//            // 3. Return output and fee, if any
//            if (applySwapFee) {
//                (, swapOutput) = _calcSwapFee(swapOutput, swapFee);
//            }
//            return (true, "", swapOutput);
//        }
//    }

    /**
      * @dev Set the ecosystem fee for redeeming a hAsset
      * @param _swapFee Fee calculated in (%/100 * 1e18)
      */
    function setSwapFee(uint256 _swapFee)
    external
    onlyGovernor
    {
        require(_swapFee <= MAX_FEE, "Rate must be within bounds");
        swapFee = _swapFee;

        emit SwapFeeChanged(_swapFee);
    }
}
