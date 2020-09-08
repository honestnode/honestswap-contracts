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
import {IPlatformIntegration} from "./interface/IPlatformIntegration.sol";
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
    event RedemptionFeeChanged(uint256 fee);

    IHonestBasket private honestBasket;
    IHonestWeight private honestWeight;
    IBassetMarket private bassetMarket;

    // Basic redemption fee information
    uint256 private redemptionFee;// 0.1% == 1e15 FULL SCALE 1e18
    uint256 private MAX_FEE;// 10%

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
        address _bAssetMarket
    )
    external
    initializer
    {
        InitializableToken._initialize(_nameArg, _symbolArg);
        InitializableModule._initialize(_nexus);
        InitializableReentrancyGuard._initialize();

        honestBasket = IHonestBasket(_honestBasket);
        honestWeight = IHonestWeight(_honestWeight);
        bassetMarket = IBassetMarket(_bAssetMarket);

        MAX_FEE = 1e17;
        redemptionFee = 1e15;
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
        uint256 quantityTransferred = HassetHelpers.transferTokens(msg.sender, address(honestBasket), _bAsset, bInfo.bAsset.isTransferFeeCharged, _bAssetQuantity);
        // Log the pool increase
        honestBasket.increasePoolBalance(bInfo.index, quantityTransferred);
        // calc weight
        // query usd price for bAsset
        (uint256 bAssetPrice, uint256 bAssetPriceDecimals) = bassetMarket.getBassetPrice(_bAsset);
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
                            honestWeight.addWeight(_recipient, 0, bonusWeight);
                        }
                    }
                }
            }
        }

        // Mint the Hasset
        _mint(_recipient, quantityTransferred);
        emit Minted(msg.sender, _recipient, quantityTransferred, _bAsset, quantityTransferred);

        return quantityTransferred;
    }

    function _validateMint(Basset memory _bAsset)
    internal
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
        BassetPropsMulti memory props = honestBasket.prepareForgeBassets(_bAssets);
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
        // Transfer the Bassets to the integrator, update storage and calc HassetQ
        for (uint256 i = 0; i < len; i++) {
            uint256 bAssetQuantity = _bAssetQuantities[i];
            if (bAssetQuantity > 0) {
                Basset memory bAsset = props.bAssets[i];

                // transfer bAsset to basket
                uint256 quantityTransferred = HassetHelpers.transferTokens(msg.sender, address(honestBasket), bAsset.addr, bAsset.isTransferFeeCharged, bAssetQuantity);

                receivedQtyArray[i] = quantityTransferred;
                hAssetQuantity = hAssetQuantity.add(quantityTransferred);

                // query usd price for bAsset
                (uint256 bAssetPrice, uint256 bAssetPriceDecimals) = bassetMarket.getBassetPrice(bAsset.addr);
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

        // update pool balance
        honestBasket.increasePoolBalances(props.indexes, receivedQtyArray);

        // add bonus weight
        if (totalBonusWeight > 0) {
            honestWeight.addWeight(_recipient, 0, totalBonusWeight);
        }

        // Mint the Hasset
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
     *      relative Hasset quantity from the sender. Sender also incurs a small fee, if any.
     * @param _bAssets          Address of the bAssets to redeem
     * @param _bAssetQuantities Units of the bAssets to redeem
     * @param _recipient        Address to credit with withdrawn bAssets
     * @return hAssetRedeemed     Relative number of hAsset units burned to pay for the bAssets
     */
    function redeemMulti(
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

        // Get high level basket info
        Basket memory basket = honestBasket.getBasket();

        // Prepare relevant data
        BassetPropsMulti memory props = honestBasket.prepareForgeBassets(_bAssets);
        if (!props.isValid) return 0;

        // Validation
        for (uint256 i = 0; i < len; i++) {
            Basset memory bAsset = props.bAssets[i];
            // Validation
            (bool mintValid, string memory reason) = _validateMint(bAsset);
            require(mintValid, reason);
        }

        // Validate redemption
        (bool redemptionValid, string memory reason) =
        _validateRedemption(basket.bassets, props.indexes, _bAssetQuantities);
        require(redemptionValid, reason);

        uint256 hAssetQuantity = 0;
        // Calc total redeemed hAsset quantity
        for (uint256 i = 0; i < len; i++) {
            uint256 bAssetQuantity = _bAssetQuantities[i];
            if (bAssetQuantity > 0) {
                hAssetQuantity = hAssetQuantity.add(bAssetQuantity);
            }
        }
        require(hAssetQuantity > 0, "Must redeem some bAssets");

        // Redemption has fee? Fetch the rate
        uint256 fee = _inProportion ? 0 : redemptionFee;

        // Apply fees, burn hAsset and return bAsset to recipient
        _settleRedemption(_recipient, hAssetQuantity, props.bAssets, _bAssetQuantities, props.indexes, props.integrators, fee);

        emit Redeemed(msg.sender, _recipient, hAssetQuantity, _bAssets, _bAssetQuantities);
        return hAssetQuantity;
    }

    /**
     * @notice Checks whether a given redemption is valid and returns the result
     * @param _allBassets       Array of all bAsset information
     * @param _indices          Indexes of the bAssets to redeem
     * @param _bAssetQuantities Quantity of bAsset to redeem
     * @return isValid          Bool to signify that the redemption is allowed
     * @return reason           If the redemption is invalid, this is the reason
     * @return feeRequired      Does this redemption require the swap fee to be applied
     */
    function _validateRedemption(
        Basset[] memory _allBassets,
        uint8[] memory _indices,
        uint256[] memory _bAssetQuantities
    )
    internal
    returns (bool, string memory)
    {
        uint256 idxCount = _indices.length;
        if (idxCount != _bAssetQuantities.length || idxCount <= 0) {
            return (false, "Input arrays must have equal length");
        }
        uint256 len = _allBassets.length;

        // check bAsset status
        for (uint256 i = 0; i < len; i++) {
            BassetStatus status = _allBassets[i].status;
            if (status == BassetStatus.Blacklisted) {
                return (false, "Basket contains blacklisted bAsset");
            } else if (
                status == BassetStatus.Liquidating ||
                status == BassetStatus.Liquidated ||
                status == BassetStatus.Failed
            ) {
                return (false, "Must redeem proportionately");
            }
        }

        // check balance and proportion
        for (uint256 i = 0; i < idxCount; i++) {
            uint8 idx = _indices[i];
            if (idx < 0 || idx >= _allBassets.length) return (false, "Basset does not exist");

            Basset memory bAsset = _allBassets[idx];
            uint256 quantity = _bAssetQuantities[i];
            uint256 poolBalance = bAsset.poolBalance.add(bAsset.savingBalance);
            // TODO
            if (quantity > poolBalance) {
                return (false, "Cannot redeem more bAssets than are in the pool");
            }
        }

        return (true, "");
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
        honestBasket.decreasePoolBalances(_indices, _bAssetQuantities);

        // Transfer the Bassets to the recipient
        uint256 bAssetCount = _bAssets.length;
        for (uint256 i = 0; i < bAssetCount; i++) {
            Basset memory bAsset = _bAssets[i];
            address bAssetAddr = _bAssets[i].addr;
            uint256 q = _bAssetQuantities[i];
            address integrator = _integrators[i];
            if (q > 0) {
                // Deduct the redemption fee, if any
                (uint256 fee, uint256 outputMinusFee) = _deductRedeemFee(bAssetAddr, q, _feeRate);
                q = outputMinusFee;

                // TODO update fee/poo/ balance
                honestBasket.increaseFeeBalance(_indices[i], fee);

                // use pool balance first
                if (bAsset.poolBalance >= q) {

                }else{
                    // still need to withdraw from platform TODO

                }

                // Transfer the Bassets to the user
//                function transferTokens(
//                address _sender,
//                address _recipient,
//                address _basset,
//                bool _erc20TransferFeeCharged,
//            uint256 _qty
//            )
                uint256 quantityTransferred = HassetHelpers.transferTokens(address(honestBasket), _recipient, bAssetAddr, bAsset.isTransferFeeCharged, q);
                IPlatformIntegration(integrator).withdraw(_recipient, bAssetAddr, q, bAsset.isTransferFeeCharged);
            }
        }
    }


    /***************************************
                    INTERNAL
    ****************************************/

    /**
     * @dev Pay the forging fee by burning relative amount of hAsset
     * @param _bAssetQuantity     Exact amount of bAsset being swapped out
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
      * @dev Set the ecosystem fee for redeeming a hAsset
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
      * @dev Gets the address of the BasketManager for this hAsset
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
     *      amount of hAsset and sending it over to the SavingsManager.
     * @return totalInterestGained   Equivalent amount of hAsset units that have been generated
     * @return newSupply             New total hAsset supply
     */
    //    function collectInterest()
    //    external
    //    onlySavingsManager
    //    nonReentrant
    //    returns (uint256 totalInterestGained, uint256 newSupply)
    //    {
    //        (uint256 interestCollected, uint256[] memory gains) = basketManager.collectInterest();
    //
    //        // mint new hAsset to sender
    //        _mint(msg.sender, interestCollected);
    //        emit MintedMulti(address(this), address(this), interestCollected, new address[](0), gains);
    //
    //        return (interestCollected, totalSupply());
    //    }
}
