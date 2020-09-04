pragma solidity 0.5.16;

// Libs
import {Initializable} from "@openzeppelin/upgrades/contracts/Initializable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {InitializableToken} from "./common/InitializableToken.sol";
import {InitializableModule} from "./common/InitializableModule.sol";
import {InitializableReentrancyGuard} from "./common/InitializableReentrancyGuard.sol";
import {IHasset} from "./interface/IHasset.sol";
import {IHonestBasket} from "./interface/IHonestBasket.sol";
import {IBassetMarket} from "./interface/IBassetMarket.sol";
import {IHonestWeight} from "./interface/IHonestWeight.sol";
import {HassetHelpers} from "./util/HassetHelpers.sol";
import {HonestMath} from "./util/HonestMath.sol";

contract Hasset is
Initializable,
IHasset,
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
    event RedeemedHasset(address indexed redeemer, address recipient, uint256 hAssetQuantity);
    event PaidFee(address indexed payer, address asset, uint256 feeQuantity);

    // State Events
    event SwapFeeChanged(uint256 fee);
    event RedemptionFeeChanged(uint256 fee);
    event ForgeValidatorChanged(address forgeValidator);

    IHonestBasket private honestBasket;
    IHonestWeight private honestWeight;
    IBassetMarket private bassetMarket;

    // Basic redemption fee information
    uint256 public swapFee;// 0.1%
    uint256 private MAX_FEE;// 10%

    uint256 public redemptionFee;

    /**
     * @dev Constructor
     * @notice To avoid variable shadowing appended `Arg` after arguments name.
     */
    function initialize(
        string calldata _nameArg,
        string calldata _symbolArg,
        address _nexus,
        address _honestBasket,
        address _honestWeight,
        address _bassetMarket
    )
    external
    initializer
    {
        InitializableToken._initialize(_nameArg, _symbolArg);
        InitializableModule._initialize(_nexus);
        InitializableReentrancyGuard._initialize();

        honestBasket = IHonestBasket(_honestBasket);
        honestWeight = IHonestWeight(_honestWeight);
        bassetMarket = IBassetMarket(_bassetMarket);

        MAX_FEE = 0.1;
        swapFee = 0.001;
    }

    modifier onlySavingsManager() {
        require(_savingsManager() == msg.sender, "Must be savings manager");
        _;
    }

    /**
     * @dev Mint a single hAsset, at a 1:1 ratio with the bAsset. This contract
     *      must have approval to spend the senders bAsset
     * @param _bAsset         Address of the bAsset to mint
     * @param _bAssetQuantity Quantity in bAsset units
     * @return hAssetMinted   Number of newly minted hAssets
     */
    function mint(
        address _bAsset,
        uint256 _bAssetQuantity
    )
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
     * @param _recipient        Address to receive the newly minted mAsset tokens
     * @return hAssetMinted     Number of newly minted hAssets
     */
    function mintMulti(
        address[] calldata _bAssets,
        uint256[] calldata _bAssetQuantity,
        address _recipient
    )
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
        (bool isValid, BassetDetails memory bInfo) = honestBasket.prepareForgeBasset(_bAsset);
        if (!isValid) return 0;

        // Validation
        (bool mintValid, string memory reason) = _validateMint(bInfo.bAsset);
        require(mintValid, reason);

        // transfer bAsset to basket
        uint256 quantityTransferred = HassetHelpers.transferTokens(msg.sender, getBasketManager(), _bAsset, bInfo.bAsset.isTransferFeeCharged, _bAssetQuantity);
        // Log the pool increase
        honestBasket.increasePoolBalance(bInfo.index, quantityTransferred);
        // calc weight

        // query usd price for bAsset
        uint256 bAssetPrice = bassetMarket.getBassetPrice(_bAsset);
        if (bAssetPrice > 1) {
            uint256 bonusWeightFactor = bAssetPrice.sub(1);
            bonusWeightFactor = bonusWeightFactor.sub(swapFee);
            uint256 bonusWeight = bonusWeightFactor.mul(quantityTransferred);
            if (bonusWeight > 0) {
                // add bonus weight
                honestWeight.addWeight(_recipient, bonusWeight);
            }
        }

        // Mint the Masset
        _mint(_recipient, quantityTransferred);
        emit Minted(msg.sender, _recipient, quantityTransferred, _bAsset, quantityTransferred);

        return quantityTransferred;
    }

    function _validateMint(Basset calldata _bAsset)
    internal
    pure
    returns (bool isValid, string memory reason)
    {
        if (
            _bAsset.status == BassetStatus.Liquidating ||
            _bAsset.status == BassetStatus.Blacklisted
        ) {
            return (false, "bAsset not allowed in mint");
        }
        return (true, "");
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

        // Load only needed bAssets in array
        ForgePropsMulti memory props
        = honestBasket.prepareForgeBassets(_bAssets);
        if (!props.isValid) return 0;

        uint256 hAssetQuantity = 0;
        uint256[] memory receivedQtyArray = new uint256[](len);

        // Validation
        for (uint256 i = 0; i < len; i++) {
            Basset memory bAsset = props.bAssets[i];
            // Validation
            (bool mintValid, string memory reason) = _validateMint(bAsset);
            require(mintValid, reason);
        }

        uint256 totalBonusWeight = 0;
        // Transfer the Bassets to the integrator, update storage and calc MassetQ
        for (uint256 i = 0; i < len; i++) {
            uint256 bAssetQuantity = _bAssetQuantities[i];
            if (bAssetQuantity > 0) {
                Basset memory bAsset = props.bAssets[i];

                // transfer bAsset to basket
                uint256 quantityTransferred = HassetHelpers.transferTokens(msg.sender, getBasketManager(), bAsset.addr, bAsset.isTransferFeeCharged, bAssetQuantity);

                receivedQtyArray[i] = quantityTransferred;
                hAssetQuantity = hAssetQuantity.add(quantityTransferred);

                // query usd price for bAsset
                uint256 bAssetPrice = bassetMarket.getBassetPrice(bAsset.addr);
                if (bAssetPrice > 1) {
                    uint256 bonusWeightFactor = bAssetPrice.sub(1);
                    bonusWeightFactor = bonusWeightFactor.sub(swapFee);
                    uint256 bonusWeight = bonusWeightFactor.mul(quantityTransferred);
                    if (bonusWeight > 0) {
                        totalBonusWeight.add(bonusWeight);
                    }
                }
            }
        }
        require(hAssetQuantity > 0, "No hAsset quantity to mint");

        // update pool balance
        honestBasket.increasePoolBalances(props.indexes, receivedQtyArray);

        // add bonus weight
        if (totalBonusWeight > 0) {
            honestWeight.addWeight(_recipient, totalBonusWeight);
        }

        // Mint the Hasset
        _mint(_recipient, hAssetQuantity);
        emit MintedMulti(msg.sender, _recipient, hAssetQuantity, _bAssets, _bAssetQuantities);

        return hAssetQuantity;
    }

    /** @dev Deposits tokens into the platform integration and returns the ratioed amount */
    function _depositTokens(
        address _bAsset,
        uint256 _bAssetRatio,
        address _integrator,
        bool _erc20TransferFeeCharged,
        uint256 _quantity
    )
    internal
    returns (uint256 quantityDeposited, uint256 ratioedDeposit)
    {
        quantityDeposited = _depositTokens(_bAsset, _integrator, _erc20TransferFeeCharged, _quantity);
        ratioedDeposit = quantityDeposited.mulRatioTruncate(_bAssetRatio);
    }

    /** @dev Deposits tokens into the platform integration and returns the deposited amount */
    function _depositTokens(
        address _bAsset,
        address _integrator,
        bool _erc20TransferFeeCharged,
        uint256 _quantity
    )
    internal
    returns (uint256 quantityDeposited)
    {
        uint256 quantityTransferred = MassetHelpers.transferTokens(msg.sender, _integrator, _bAsset, _erc20TransferFeeCharged, _quantity);
        uint256 deposited = IPlatformIntegration(_integrator).deposit(_bAsset, quantityTransferred, _erc20TransferFeeCharged);
        quantityDeposited = StableMath.min(deposited, _quantity);
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
    returns (uint256 output)
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
        basketManager.prepareSwapBassets(_input, _output, false);
        require(isValid, reason);

        // 3. Deposit the input tokens
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
     * @param _output       Asset to receive - bAsset or mAsset(this)
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
        // 2.1. If output is mAsset(this), then calculate a simple mint
        if (isMint) {
            // Validate mint
            (isValid, reason) = forgeValidator.validateMint(totalSupply(), inputDetails.bAsset, quantity);
            if (!isValid) return (false, reason, 0);
            // Simply cast the quantity to mAsset
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
     *      relative Hasset quantity from the sender. Sender also incurs a small fee, if any.
     * @param _bAssets          Address of the bAssets to redeem
     * @param _bAssetQuantities Units of the bAssets to redeem
     * @param _recipient        Address to credit with withdrawn bAssets
     * @return hAssetRedeemed     Relative number of hAsset units burned to pay for the bAssets
     */
    function redeemMulti(
        address[] calldata _bAssets,
        uint256[] calldata _bAssetQuantities,
        address _recipient
    )
    external
    nonReentrant
    returns (uint256 hAssetRedeemed)
    {
        return _redeemTo(_bAssets, _bAssetQuantities, _recipient);
    }

    /**
     * @dev Credits a recipient with a proportionate amount of bAssets, relative to current vault
     * balance levels and desired hAsset quantity. Burns the hAsset as payment.
     * @param _hAssetQuantity   Quantity of mAsset to redeem
     * @param _recipient        Address to credit the withdrawn bAssets
     */
    function redeemHasset(
        uint256 _hAssetQuantity,
        address _recipient
    )
    external
    nonReentrant
    {
        _redeemHasset(_hAssetQuantity, _recipient);
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
        return _redeemTo(bAssets, quantities, _recipient);
    }

    /** @dev Redeem hAsset for one or more bAssets */
    function _redeemTo(
        address[] memory _bAssets,
        uint256[] memory _bAssetQuantities,
        address _recipient
    )
    internal
    returns (uint256 hAssetRedeemed)
    {
        require(_recipient != address(0), "Must be a valid recipient");
        uint256 bAssetCount = _bAssetQuantities.length;
        require(bAssetCount > 0 && bAssetCount == _bAssets.length, "Input array mismatch");

        // Get high level basket info
        Basket memory basket = honestBasket.getBasket();

        // Prepare relevant data
        ForgePropsMulti memory props = honestBasket.prepareForgeBassets(_bAssets);
        if (!props.isValid) return 0;

        // Validation
        for (uint256 i = 0; i < len; i++) {
            Basset memory bAsset = props.bAssets[i];
            // Validation
            (bool mintValid, string memory reason) = _validateMint(bAsset);
            require(mintValid, reason);
        }

        // Validate redemption
        (bool redemptionValid, string memory reason, bool applyFee) =
        _validateRedemption(basket.bassets, props.indexes, _bAssetQuantities);
        require(redemptionValid, reason);

        uint256 hAssetQuantity = 0;

        // Calc total redeemed hAsset quantity
        for (uint256 i = 0; i < bAssetCount; i++) {
            uint256 bAssetQuantity = _bAssetQuantities[i];
            if (bAssetQuantity > 0) {
                hAssetQuantity = hAssetQuantity.add(bAssetQuantity);
            }
        }
        require(hAssetQuantity > 0, "Must redeem some bAssets");

        // Redemption has fee? Fetch the rate
        uint256 fee = applyFee ? swapFee : 0;

        // Apply fees, burn hAsset and return bAsset to recipient
        _settleRedemption(_recipient, hAssetQuantity, props.bAssets, _bAssetQuantities, props.indexes, props.integrators, fee);

        emit Redeemed(msg.sender, _recipient, hAssetQuantity, _bAssets, _bAssetQuantities);
        return hAssetQuantity;
    }

    /**
     * @notice Checks whether a given redemption is valid and returns the result
     * @dev A redemption is valid if it does not push any untouched bAssets above their
     * max weightings. In addition, if bAssets are currently above their max weight
     * (i.e. during basket composition changes) they must be redeemed
     * @param _allBassets       Array of all bAsset information
     * @param _indices          Indexes of the bAssets to redeem
     * @param _bAssetQuantities Quantity of bAsset to redeem
     * @return isValid          Bool to signify that the redemption is allowed
     * @return reason           If the redemption is invalid, this is the reason
     * @return feeRequired      Does this redemption require the swap fee to be applied
     */
    function _validateRedemption(
        Basset[] calldata _bAssets,
        uint8[] calldata _indices,
        uint256[] calldata _bAssetQuantities
    )
    returns (bool, string memory, bool)
    {
        uint256 idxCount = _indices.length;
        if (idxCount != _bAssetQuantities.length) return (false, "Input arrays must have equal length", false);

        uint256 len = _bAssets.length;
        // check bAsset status
        for (uint256 i = 0; i < len; i++) {
            BassetStatus status = _bAssets[i].status;
            if (status == BassetStatus.Blacklisted) {
                response.isValid = false;
                response.reason = "Basket contains blacklisted bAsset";
                return (false, "Basket contains blacklisted bAsset", false);
            } else if (
                status == BassetStatus.Liquidating ||
                status == BassetStatus.Liquidated ||
                status == BassetStatus.Failed
            ) {
                return (false, "Must redeem proportionately", false);
            }
        }

        uint256 newTotalVault = _totalVault;
        bool applySwapFee = true;

        // check balance and proportion
        for (uint256 i = 0; i < idxCount; i++) {
            uint8 idx = _indices[i];
            if (idx >= _allBassets.length) return (false, "Basset does not exist", false);

            Basset memory bAsset = _bAssets[idx];
            uint256 quantity = _bAssetQuantities[i];
            if (quantity > bAsset.poolBalance) return (false, "Cannot redeem more bAssets than are in the pool", false);

            // Calculate ratioed redemption amount in mAsset terms
            uint256 ratioedRedemptionAmount = quantity.mulRatioTruncate(bAsset.ratio);
            // Subtract ratioed redemption amount from both vault and total supply
            data.ratioedBassetVaults[idx] = data.ratioedBassetVaults[idx].sub(ratioedRedemptionAmount);

            newTotalVault = newTotalVault.sub(ratioedRedemptionAmount);
        }

        if (idxCount != len) {

        }

        return (true, "", applySwapFee);
    }


    /** @dev Redeem mAsset for a multiple bAssets */
    function _redeemMasset(
        uint256 _hAssetQuantity,
        address _recipient
    )
    internal
    {
        require(_recipient != address(0), "Must be a valid recipient");
        require(_hAssetQuantity > 0, "Invalid redemption quantity");

        // Fetch high level details
        RedeemPropsMulti memory props = basketManager.prepareRedeemMulti();
        uint256 colRatio = StableMath.min(props.colRatio, StableMath.getFullScale());

        // Ensure payout is related to the collateralised mAsset quantity
        uint256 collateralisedMassetQuantity = _hAssetQuantity.mulTruncate(colRatio);

        // Calculate redemption quantities
        (bool redemptionValid, string memory reason, uint256[] memory bAssetQuantities) =
        forgeValidator.calculateRedemptionMulti(collateralisedMassetQuantity, props.bAssets);
        require(redemptionValid, reason);

        // Apply fees, burn mAsset and return bAsset to recipient
        _settleRedemption(_recipient, _hAssetQuantity, props.bAssets, bAssetQuantities, props.indexes, props.integrators, redemptionFee);

        emit RedeemedHasset(msg.sender, _recipient, _hAssetQuantity);
    }

    /**
     * @dev Internal func to update contract state post-redemption
     * @param _recipient        Recipient of the bAssets
     * @param _hAssetQuantity   Total amount of hAsset to burn from sender
     * @param _bAssets          Array of bAssets to redeem
     * @param _bAssetQuantities Array of bAsset quantities
     * @param _indices          Matching indices for the bAsset array
     * @param _integrators      Matching integrators for the bAsset array
     * @param _feeRate          Fee rate to be applied to this redemption
     */
    function _settleRedemption(
        address _recipient,
        uint256 _hAssetQuantity,
        Basset[] memory _bAssets,
        uint256[] memory _bAssetQuantities,
        uint8[] memory _indices,
        address[] memory _integrators,
        uint256 _feeRate
    ) internal {
        // Burn the full amount of Hasset
        _burn(msg.sender, _hAssetQuantity);

        // Reduce the amount of bAssets marked in the vault
        honestBasket.decreasePoolBalances(_indices, _integrators, _bAssetQuantities);

        // Transfer the Bassets to the recipient
        uint256 bAssetCount = _bAssets.length;
        for (uint256 i = 0; i < bAssetCount; i++) {
            address bAsset = _bAssets[i].addr;
            uint256 q = _bAssetQuantities[i];
            if (q > 0) {
                // Deduct the redemption fee, if any
                q = _deductSwapFee(bAsset, q, _feeRate);
                // Transfer the Bassets to the user
                IPlatformIntegration(_integrators[i]).withdraw(_recipient, bAsset, q, _bAssets[i].isTransferFeeCharged);
            }
        }
    }


    /***************************************
                    INTERNAL
    ****************************************/

    /**
     * @dev Pay the forging fee by burning relative amount of mAsset
     * @param _bAssetQuantity     Exact amount of bAsset being swapped out
     */
    function _deductSwapFee(address _asset, uint256 _bAssetQuantity, uint256 _feeRate)
    private
    returns (uint256 outputMinusFee)
    {

        outputMinusFee = _bAssetQuantity;

        if (_feeRate > 0) {
            (uint256 fee, uint256 output) = _calcSwapFee(_bAssetQuantity, _feeRate);
            outputMinusFee = output;
            emit PaidFee(msg.sender, _asset, fee);
        }
    }

    /**
     * @dev Pay the forging fee by burning relative amount of mAsset
     * @param _bAssetQuantity     Exact amount of bAsset being swapped out
     */
    function _calcSwapFee(uint256 _bAssetQuantity, uint256 _feeRate)
    private
    pure
    returns (uint256 feeAmount, uint256 outputMinusFee)
    {
        // e.g. for 500 massets.
        // feeRate == 1% == 1e16. _quantity == 5e20.
        // (5e20 * 1e16) / 1e18 = 5e18
        feeAmount = _bAssetQuantity.mulTruncate(_feeRate);
        outputMinusFee = _bAssetQuantity.sub(feeAmount);
    }

    /***************************************
                    STATE
    ****************************************/

    /**
      * @dev Upgrades the version of ForgeValidator protocol. Governor can do this
      *      only while ForgeValidator is unlocked.
      * @param _newForgeValidator Address of the new ForgeValidator
      */
    function upgradeForgeValidator(address _newForgeValidator)
    external
    onlyGovernor
    {
        require(!forgeValidatorLocked, "Must be allowed to upgrade");
        require(_newForgeValidator != address(0), "Must be non null address");
        forgeValidator = IForgeValidator(_newForgeValidator);
        emit ForgeValidatorChanged(_newForgeValidator);
    }

    /**
      * @dev Locks the ForgeValidator into it's final form. Called by Governor
      */
    function lockForgeValidator()
    external
    onlyGovernor
    {
        forgeValidatorLocked = true;
    }

    /**
      * @dev Set the ecosystem fee for redeeming a mAsset
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

    /**
      * @dev Set the ecosystem fee for redeeming a mAsset
      * @param _redemptionFee Fee calculated in (%/100 * 1e18)
      */
    function setRedemptionFee(uint256 _redemptionFee)
    external
    onlyGovernor
    {
        require(_redemptionFee <= MAX_FEE, "Rate must be within bounds");
        redemptionFee = _redemptionFee;

        emit RedemptionFeeChanged(_redemptionFee);
    }

    /**
      * @dev Gets the address of the BasketManager for this mAsset
      * @return basketManager Address
      */
    function getBasketManager()
    external
    view
    returns (address)
    {
        return address(honestBasket);
    }

    /***************************************
                    INFLATION
    ****************************************/

    /**
     * @dev Collects the interest generated from the Basket, minting a relative
     *      amount of mAsset and sending it over to the SavingsManager.
     * @return totalInterestGained   Equivalent amount of mAsset units that have been generated
     * @return newSupply             New total mAsset supply
     */
    function collectInterest()
    external
    onlySavingsManager
    nonReentrant
    returns (uint256 totalInterestGained, uint256 newSupply)
    {
        (uint256 interestCollected, uint256[] memory gains) = basketManager.collectInterest();

        // mint new mAsset to sender
        _mint(msg.sender, interestCollected);
        emit MintedMulti(address(this), address(this), interestCollected, new address[](0), gains);

        return (interestCollected, totalSupply());
    }
}
