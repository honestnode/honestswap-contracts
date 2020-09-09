pragma solidity 0.5.16;

// Libs
import {Initializable} from "@openzeppelin/upgrades/contracts/Initializable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {InitializableToken} from "../common/InitializableToken.sol";
import {InitializableModule} from "../common/InitializableModule.sol";
import {InitializableReentrancyGuard} from "../common/InitializableReentrancyGuard.sol";
import {IHAsset} from "../interfaces/IHAsset.sol";
import {IHonestBasket} from "../interfaces/IHonestBasket.sol";
import {IHonestSaving} from "../interfaces/IHonestSaving.sol";
import {IHonestBonus} from "../interfaces/IHonestBonus.sol";
import {IHonestFee} from "../interfaces/IHonestFee.sol";
import {IBAssetValidator} from "../validator/IBAssetValidator.sol";
import {IPlatformIntegration} from "../interfaces/IPlatformIntegration.sol";
import {IBAssetPrice} from "../price/IBAssetPrice.sol";
import {HAssetHelpers} from "../util/HAssetHelpers.sol";
import {HonestMath} from "../util/HonestMath.sol";

contract HAsset is
Initializable,
IHAsset,
InitializableToken,
InitializableModule,
InitializableReentrancyGuard {

    using SafeMath for uint256;
    using HonestMath for uint256;

    // Forging Events
    event Minted(address indexed minter, address recipient, uint256 hAssetQuantity, address bAsset, uint256 bAssetQuantity);
    event MintedMulti(address indexed minter, address recipient, uint256 hAssetQuantity, address[] bAssets, uint256[] bAssetQuantities);
    event Swapped(address indexed swapper, address input, address output, uint256 outputAmount, address recipient);
    event Redeemed(address indexed redeemer, address recipient, uint256 hAssetQuantity, address[] bAssets, uint256[] bAssetQuantities);
    event RedeemedHAsset(address indexed redeemer, address recipient, uint256 hAssetQuantity);
    event PaidFee(address indexed payer, address asset, uint256 feeQuantity);

    // State Events
    event RedemptionFeeChanged(uint256 fee);

    IHonestBasket private honestBasketInterface;
    IBAssetPrice private bAssetPriceInterface;
    IHonestBonus private honestBonusInterface;
    IHonestFee private honestFeeInterface;
    IBAssetValidator private bAssetValidator;

    /**
     * @dev Constructor
     * @notice To avoid variable shadowing appended `Arg` after arguments name.
     */
    function initialize(
        string calldata _nameArg,
        string calldata _symbolArg,
        address _nexus,
        address _honestBasketInterface,
        address _honestSavingInterface,
        address _bAssetPriceInterface,
        address _honestBonusInterface,
        address _honestFeeInterface,
        address _bAssetValidator
    )
    external
    initializer
    {
        InitializableToken._initialize(_nameArg, _symbolArg);
        InitializableModule._initialize(_nexus);
        InitializableReentrancyGuard._initialize();

        honestBasketInterface = IHonestBasket(_honestBasketInterface);
        honestSavingInterface = IHonestSaving(_honestSavingInterface);
        bAssetPriceInterface = IBAssetPrice(_bAssetPriceInterface);
        honestBonus = IHonestBonus(_honestBonusInterface);
        honestFeeInterface = IHonestFee(_honestFeeInterface);
        bAssetValidator = IBAssetValidator(_bAssetValidator);
    }

    //    modifier onlySavingsManager() {
    //        require(_savingsManager() == msg.sender, "Must be savings manager");
    //        _;
    //    }

    /**
     * @dev Mint a single hAsset, at a 1:1 ratio with the bAsset. This contract
     *      must have approval to spend the senders bAsset
     * @param _bAsset         Address of the bAsset to mint
     * @param _bAssetQuantity Quantity in bAsset units
     * @return hAssetMinted   Number of newly minted hAssets
     */
    function mint(address _bAsset, uint256 _bAssetQuantity)
    external
    nonReentrant
    returns (uint256 hAssetMinted)
    {
        return _mintTo(_bAsset, _bAssetQuantity, msg.sender);
    }

    /**
     * @dev Mint a single bAsset, at a 1:1 ratio with the bAsset. This contract
     *      must have approval to spend the senders bAsset
     * @param _bAsset         Address of the bAsset to mint
     * @param _bAssetQuantity Quantity in bAsset units
     * @param _recipient receipient of the newly minted mAsset tokens
     * @return hAssetMinted   Number of newly minted hAssets
     */
    function mintTo(
        address _bAsset,
        uint256 _bAssetQuantity,
        address _recipient
    )
    external
    nonReentrant
    returns (uint256 hAssetMinted)
    {
        return _mintTo(_bAsset, _bAssetQuantity, _recipient);
    }


    /**
     * @dev Mint with multiple bAssets, at a 1:1 ratio to mAsset. This contract
     *      must have approval to spend the senders bAssets
     * @param _bAssets          Non-duplicate address array of bAssets with which to mint
     * @param _bAssetQuantity   Quantity of each bAsset to mint. Order of array
     *                          should mirror the above
     * @return hAssetMinted     Number of newly minted hAssets
     */
    function mintMulti(address[] calldata _bAssets, uint256[] calldata _bAssetQuantity)
    external
    nonReentrant
    returns (uint256 hAssetMinted)
    {
        return _mintTo(_bAssets, _bAssetQuantity, msg.sender);
    }

    /**
     * @dev Mint with multiple bAssets, at a 1:1 ratio to mAsset. This contract
     *      must have approval to spend the senders bAssets
     * @param _bAssets          Non-duplicate address array of bAssets with which to mint
     * @param _bAssetQuantity   Quantity of each bAsset to mint. Order of array
     *                          should mirror the above
     * @param _recipient        recipient of the newly minted mAsset tokens
     * @return hAssetMinted     Number of newly minted hAssets
     */
    function mintMultiTo(address[] calldata _bAssets, uint256[] calldata _bAssetQuantity, address _recipient)
    external
    nonReentrant
    returns (uint256 hAssetMinted)
    {
        return _mintTo(_bAssets, _bAssetQuantity, _recipient);
    }

    /***************************************
              MINTING (INTERNAL)
    ****************************************/

    /** @dev Mint Single */
    function _mintTo(
        address _bAsset,
        uint256 _bAssetQuantity,
        address _recipient
    )
    internal
    returns (uint256 hAssetMinted)
    {
        require(_recipient != address(0), "Must be a valid recipient");
        require(_bAssetQuantity > 0, "Quantity must not be 0");

        // check exist, get Basset detail
        (bool bAssetExist, uint8 bAssetStatus) = honestBasketInterface.getBAssetStatus(_bAsset);
        require(bAssetExist, "bAsset not exist in the Basket!");
        // Validation
        (bool mintValid, string memory reason) = bAssetValidator.validateMint(_bAsset, bAssetStatus, _bAssetQuantity);
        require(mintValid, reason);

        // transfer bAsset to basket
        uint256 quantityTransferred = HAssetHelpers.transferTokens(msg.sender, getBasketAddress(), _bAsset, false, _bAssetQuantity);
        // calc weight
        // query usd price for bAsset
        (uint256 bAssetPrice, uint256 bAssetPriceDecimals) = bAssetPriceInterface.getBassetPrice(_bAsset);
        if (bAssetPrice > 0 && bAssetPriceDecimals > 0) {
            uint256 priceScale = 10 ** bAssetPriceDecimals;
            if (bAssetPrice > priceScale) {
                uint256 bonusWeightFactor = bAssetPrice.sub(priceScale);
                if (bonusWeightFactor > 0) {
                    uint256 feeFactor = redemptionFee.mulTruncate(priceScale);
                    bonusWeightFactor = bonusWeightFactor.sub(feeFactor);
                    if (bonusWeightFactor > 0) {
                        uint256 bonusWeight = bonusWeightFactor.mulTruncateScale(quantityTransferred, priceScale);
                        if (bonusWeight > 0) {
                            // add bonus weight
                            honestBonusInterface.addBonus(_recipient, bonusWeight);
                        }
                    }
                }
            }
        }

        // Mint the HAsset
        _mint(_recipient, quantityTransferred);
        emit Minted(msg.sender, _recipient, quantityTransferred, _bAsset, quantityTransferred);

        return quantityTransferred;
    }

    /** @dev Mint Multi */
    function _mintTo(
        address[] memory _bAssets,
        uint256[] memory _bAssetQuantities,
        address _recipient
    )
    internal
    returns (uint256 hAssetMinted)
    {
        require(_recipient != address(0), "Must be a valid recipient");
        uint256 len = _bAssetQuantities.length;
        require(len > 0 && len == _bAssets.length, "Input array mismatch");

        (bool bAssetExist, uint8[] memory statuses) = honestBasketInterface.getBAssetsStatus(_bAssets);
        require(bAssetExist, "bAsset not exist in the Basket!");

        // Load only needed bAssets in array
        (bool mintValid, string memory reason) = bAssetValidator.validateMintMulti(_bAssets, statuses, _bAssetQuantities);
        require(mintValid, reason);

        uint256 hAssetQuantity = 0;
        uint256[] memory receivedQtyArray = new uint256[](len);

        uint256 totalBonusWeight = 0;
        (uint256[] memory prices, uint256[] memory decimals) = bAssetPriceInterface.getBAssetsPrice(_bAssets);
        require(len == prices.length, "bAsset price array count mismatch");
        for (uint256 i = 0; i < len; i++) {
            uint256 bAssetQuantity = _bAssetQuantities[i];
            address bAssetAddress = _bAssets[i];
            if (bAssetQuantity > 0) {
                // transfer bAsset to basket
                uint256 quantityTransferred = HAssetHelpers.transferTokens(msg.sender, getBasketAddress(), bAssetAddress, false, bAssetQuantity);

                receivedQtyArray[i] = quantityTransferred;
                hAssetQuantity = hAssetQuantity.add(quantityTransferred);

                // query usd price for bAsset
                uint256 bAssetPrice = prices[i];
                uint256 bAssetPriceDecimals = decimals[i];
                if (bAssetPrice > 0 && bAssetPriceDecimals > 0) {
                    uint256 priceScale = 10 ** bAssetPriceDecimals;
                    if (bAssetPrice > priceScale) {
                        uint256 bonusWeightFactor = bAssetPrice.sub(priceScale);
                        if (bonusWeightFactor > 0) {
                            uint256 feeFactor = redemptionFee.mulTruncate(priceScale);
                            bonusWeightFactor = bonusWeightFactor.sub(feeFactor);
                            if (bonusWeightFactor > 0) {
                                uint256 bonusWeight = bonusWeightFactor.mulTruncateScale(quantityTransferred, priceScale);
                                if (bonusWeight > 0) {
                                    totalBonusWeight.add(bonusWeight);
                                }
                            }
                        }
                    }
                }
            }
        }
        require(hAssetQuantity > 0, "No hAsset quantity to mint");

        // add bonus weight
        if (totalBonusWeight > 0) {
            honestBonusInterface.addBonus(_recipient, totalBonusWeight);
        }

        // Mint the HAsset
        _mint(_recipient, hAssetQuantity);
        emit MintedMulti(msg.sender, _recipient, hAssetQuantity, _bAssets, _bAssetQuantities);

        return hAssetQuantity;
    }

    /***************************************
              REDEMPTION (PUBLIC)
    ****************************************/
    /**
     * @dev Credits the sender with a certain quantity of selected bAsset, in exchange for burning the
     *      relative hAsset quantity from the sender. Sender also incurs a small hAsset fee, if any.
     * @param _bAsset           Address of the bAsset to redeem
     * @param _bAssetQuantity   Units of the bAsset to redeem
     * @return hAssetRedeemed     Relative number of hAsset units burned to pay for the bAssets
     */
    function redeem(
        address _bAsset,
        uint256 _bAssetQuantity
    )
    external
    nonReentrant
    returns (uint256 hAssetRedeemed)
    {
        return _redeemTo(_bAsset, _bAssetQuantity, msg.sender);
    }

    /**
     * @dev Credits a recipient with a certain quantity of selected bAsset, in exchange for burning the
     *      relative Hasset quantity from the sender. Sender also incurs a small fee, if any.
     * @param _bAsset           Address of the bAsset to redeem
     * @param _bAssetQuantity   Units of the bAsset to redeem
     * @param _recipient        Address to credit with withdrawn bAssets
     * @return hAssetRedeemed     Relative number of hAsset units burned to pay for the bAssets
     */
    function redeemTo(
        address _bAsset,
        uint256 _bAssetQuantity,
        address _recipient
    )
    external
    nonReentrant
    returns (uint256 hAssetRedeemed)
    {
        return _redeemTo(_bAsset, _bAssetQuantity, _recipient);
    }

    /**
     * @dev Credits a recipient with a certain quantity of selected bAssets, in exchange for burning the
     *      relative HAsset quantity from the sender. Sender also incurs a small fee, if any.
     * @param _bAssets          Address of the bAssets to redeem
     * @param _bAssetQuantities Units of the bAssets to redeem
     * @param _recipient        Address to credit with withdrawn bAssets
     * @return hAssetRedeemed     Relative number of hAsset units burned to pay for the bAssets
     */
    function redeemMulti(
        address[] calldata _bAssets,
        uint256[] calldata _bAssetQuantities,
        bool _inProportion
    )
    external
    nonReentrant
    returns (uint256 hAssetRedeemed)
    {
        return _redeemTo(_bAssets, _bAssetQuantities, msg.sender, _inProportion);
    }

    /**
     * @dev Credits a recipient with a certain quantity of selected bAssets, in exchange for burning the
     *      relative HAsset quantity from the sender. Sender also incurs a small fee, if any.
     * @param _bAssets          Address of the bAssets to redeem
     * @param _bAssetQuantities Units of the bAssets to redeem
     * @param _recipient        Address to credit with withdrawn bAssets
     * @return hAssetRedeemed     Relative number of hAsset units burned to pay for the bAssets
     */
    function redeemMultiTo(
        address[] calldata _bAssets,
        uint256[] calldata _bAssetQuantities,
        address _recipient,
        bool _inProportion
    )
    external
    nonReentrant
    returns (uint256 hAssetRedeemed)
    {
        return _redeemTo(_bAssets, _bAssetQuantities, _recipient, _inProportion);
    }

    /***************************************
              REDEMPTION (INTERNAL)
    ****************************************/

    /** @dev Casting to arrays for use in redeemMulti func */
    function _redeemTo(
        address _bAsset,
        uint256 _bAssetQuantity,
        address _recipient
    )
    internal
    returns (uint256 hAssetRedeemed)
    {
        address[] memory bAssets = new address[](1);
        uint256[] memory quantities = new uint256[](1);
        bAssets[0] = _bAsset;
        quantities[0] = _bAssetQuantity;
        return _redeemTo(bAssets, quantities, _recipient, false);
    }

    /** @dev Redeem hAsset for one or more bAssets */
    function _redeemTo(
        address[] memory _bAssets,
        uint256[] memory _bAssetQuantities,
        address _recipient,
        bool _inProportion
    )
    internal
    returns (uint256 hAssetRedeemed)
    {
        require(_recipient != address(0), "Must be a valid recipient");
        uint256 len = _bAssets.length;
        require(len > 0 && len == _bAssetQuantities.length, "Input array mismatch");

        // valid target bAssets
        (bool bAssetExist, uint8[] memory statuses) = honestBasketInterface.getBAssetsStatus(_bAssets);
        require(bAssetExist, "BAsset not exist in the Basket!");

        // Load only needed bAssets in array
        (bool redeemValid, string memory reason) = bAssetValidator.validateRedeem(_bAssets, statuses, _bAssetQuantities);
        require(redeemValid, reason);

        // query basket balance
        uint256[] memory bAssetBalances = honestBasketInterface.getBasketBalance(_bAssets);
        require(len == bAssetBalances.length, "Query bAsset balance failed");

        // Calc total redeemed hAsset quantity
        uint256 hAssetQuantity = 0;
        for (uint256 i = 0; i < len; i++) {
            // check every target bAsset quantity
            require(_bAssetQuantities[i] <= bAssetBalances[i], "Cannot redeem more bAsset than balance");
            hAssetQuantity = hAssetQuantity.add(_bAssetQuantities[i]);
        }
        require(hAssetQuantity > 0, "Must redeem some bAssets");

        // Redemption has fee? Fetch the rate
        uint256 feeRate = 0;
        if (!_inProportion) {
            feeRate = honestFeeInterface.redeemFeeRate();
        }

        // Apply fees, burn hAsset and return bAsset to recipient
        //        _settleRedemption(_recipient, hAssetQuantity, props.bAssets, _bAssetQuantities, props.indexes, props.integrators, fee);
        _burn(msg.sender, hAssetQuantity);

        uint256 totalFee = 0;
        uint256[] gapQuantities = new uint256[len];
        for (uint256 i = 0; i < len; i++) {
            uint256 bAssetBalance = bAssetBalances[i];
            // Deduct the redemption fee, if any
            (uint256 fee, uint256 outputMinusFee) = _deductRedeemFee(_bAssets[i], _bAssetQuantities[i], feeRate);
            totalFee.add(fee);
            uint256 bAssetPoolBalance = IERC20(_bAssets[i]).balanceOf(getBasketAddress());
            uint256 quantityTransferred = HAssetHelpers.transferTokens(getBasketAddress(), _recipient, _bAssetsi, false, outputMinusFee);
            if (outputMinusFee <= bAssetPoolBalance) {
                // pool balance enough
                gapQuantities[i] = 0;
            } else {
                // pool balance not enough
                gapQuantities[i] = outputMinusFee.sub(bAssetPoolBalance);
            }
        }

        uint256 barrowQuantity = honestSavingInterface.borrow(_bAssets, gapQuantities);

        if (totalFee > 0) {
            honestFeeInterface.chargeRedeemFee(msg.sender, totalFee);
        }
        emit Redeemed(msg.sender, _recipient, hAssetQuantity, _bAssets, _bAssetQuantities);
        return hAssetQuantity;
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
    function swap(
        address _input,
        address _output,
        uint256 _quantity,
        address _recipient
    )
    external
    nonReentrant
    returns (uint256 outputQuantity)
    {
        require(_input != address(0) && _output != address(0), "Invalid swap asset addresses");
        require(_input != _output, "Cannot swap the same asset");
        require(_recipient != address(0), "Missing recipient address");
        require(_quantity > 0, "Invalid quantity");

        // 1. If the output is this mAsset, just mint
        if (_output == address(this)) {
            return _mintTo(_input, _quantity, _recipient);
        }

        // 2. Grab all relevant info from the Manager
        (bool isValid, string memory reason, BassetDetails memory inputDetails, BassetDetails memory outputDetails) =
        honestBasketInterface.prepareSwapBassets(_input, _output, false);
        require(isValid, reason);

        // 3. Deposit the input tokens
        // transfer bAsset to basket
        uint256 quantityTransferred = HAssetHelpers.transferTokens(msg.sender, getBasketAddress(), _input, inputDetails.bAsset.isTransferFeeCharged, _quantity);
        // Log the pool increase
        honestBasketInterface.increasePoolBalance(inputDetails.index, quantityTransferred);
        uint256 deposited = IPlatformIntegration(_integrator).deposit(_bAsset, quantityTransferred, _erc20TransferFeeCharged);
        quantityDeposited = StableMath.min(deposited, _quantity);

        uint256 quantitySwappedIn = _depositTokens(_input, inputDetails.integrator, inputDetails.bAsset.isTransferFeeCharged, _quantity);
        // 3.1. Update the input balance
        basketManager.increaseVaultBalance(inputDetails.index, inputDetails.integrator, quantitySwappedIn);

        // 4. Validate the swap
        (bool swapValid, string memory swapValidityReason, uint256 swapOutput, bool applySwapFee) =
        forgeValidator.validateSwap(totalSupply(), inputDetails.bAsset, outputDetails.bAsset, quantitySwappedIn);
        require(swapValid, swapValidityReason);

        // 5. Settle the swap
        // 5.1. Decrease output bal
        basketManager.decreaseVaultBalance(outputDetails.index, outputDetails.integrator, swapOutput);
        // 5.2. Calc fee, if any
        if (applySwapFee) {
            swapOutput = _deductSwapFee(_output, swapOutput, swapFee);
        }
        // 5.3. Withdraw to recipient
        IPlatformIntegration(outputDetails.integrator).withdraw(_recipient, _output, swapOutput, outputDetails.bAsset.isTransferFeeCharged);

        output = swapOutput;

        emit Swapped(msg.sender, _input, _output, swapOutput, _recipient);
    }


    /**
     * @dev Determines both if a trade is valid, and the expected fee or output.
     * Swap is valid if it does not result in the input asset exceeding its maximum weight.
     * @param _input        bAsset to deposit
     * @param _output       Asset to receive - bAsset or hAsset(this)
     * @param _quantity     Units of input bAsset to swap
     * @return valid        Bool to signify that swap is current valid
     * @return reason       If swap is invalid, this is the reason
     * @return output       Units of _output asset the trade would return
     */
    function getSwapOutput(
        address _input,
        address _output,
        uint256 _quantity
    )
    external
    view
    returns (bool, string memory, uint256 output)
    {
        require(_input != address(0) && _output != address(0), "Invalid swap asset addresses");
        require(_input != _output, "Cannot swap the same asset");

        bool isMint = _output == address(this);
        uint256 quantity = _quantity;

        // 1. Get relevant asset data
        (bool isValid, string memory reason, BassetDetails memory inputDetails, BassetDetails memory outputDetails) =
        basketManager.prepareSwapBassets(_input, _output, isMint);
        if (!isValid) {
            return (false, reason, 0);
        }

        // 2. check if trade is valid
        // 2.1. If output is hAsset(this), then calculate a simple mint
        if (isMint) {
            // Validate mint
            (isValid, reason) = forgeValidator.validateMint(totalSupply(), inputDetails.bAsset, quantity);
            if (!isValid) return (false, reason, 0);
            // Simply cast the quantity to hAsset
            output = quantity.mulRatioTruncate(inputDetails.bAsset.ratio);
            return (true, "", output);
        }
        // 2.2. If a bAsset swap, calculate the validity, output and fee
        else {
            (bool swapValid, string memory swapValidityReason, uint256 swapOutput, bool applySwapFee) =
            forgeValidator.validateSwap(totalSupply(), inputDetails.bAsset, outputDetails.bAsset, quantity);
            if (!swapValid) {
                return (false, swapValidityReason, 0);
            }

            // 3. Return output and fee, if any
            if (applySwapFee) {
                (, swapOutput) = _calcSwapFee(swapOutput, swapFee);
            }
            return (true, "", swapOutput);
        }
    }

    /***************************************
                    INTERNAL
    ****************************************/

    /**
     * @dev Pay the forging fee by burning relative amount of hAsset
     */
    function _deductRedeemFee(address _asset, uint256 _bAssetQuantity, uint256 _feeRate)
    private
    returns (uint256 fee, uint256 outputMinusFee)
    {
        outputMinusFee = _bAssetQuantity;
        if (_feeRate > 0) {
            fee = _bAssetQuantity.mulTruncate(_feeRate);
            outputMinusFee = _bAssetQuantity.sub(fee);

            emit PaidFee(msg.sender, _asset, fee);
        }
    }

    /**
      * @dev Gets the address of the BasketManager for this hAsset
      * @return HonestBasket contract Address
      */
    function getBasketAddress()
    public
    view
    returns (address)
    {
        return address(honestBasketInterface);
    }

}
