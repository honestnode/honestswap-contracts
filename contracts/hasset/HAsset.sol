pragma solidity ^0.5.0;

// Libs
import {Initializable} from "@openzeppelin/upgrades/contracts/Initializable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mintable} from "@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {InitializableToken} from "../common/InitializableToken.sol";
import {InitializableModule} from "../common/InitializableModule.sol";
import {InitializableReentrancyGuard} from "../common/InitializableReentrancyGuard.sol";
import {IHAsset} from "../interfaces/IHAsset.sol";
import {IHonestBasket} from "../interfaces/IHonestBasket.sol";
import {IHonestSavings} from "../interfaces/IHonestSavings.sol";
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

    event Redeemed(address indexed redeemer, address recipient, uint256 hAssetQuantity, address[] bAssets, uint256[] bAssetQuantities);
    event RedeemedHAsset(address indexed redeemer, address recipient, uint256 hAssetQuantity);
    event PaidFee(address indexed payer, address asset, uint256 feeQuantity);

    // State Events
    event RedemptionFeeChanged(uint256 fee);

    IHonestBasket private honestBasketInterface;
    IBAssetPrice private bAssetPriceInterface;
    IHonestBonus private honestBonusInterface;
    IHonestFee private honestFeeInterface;
    IHonestSavings private honestSavingsInterface;
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
        address _honestSavingsInterface,
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
        honestSavingsInterface = IHonestSavings(_honestSavingsInterface);
        bAssetPriceInterface = IBAssetPrice(_bAssetPriceInterface);
        honestBonusInterface = IHonestBonus(_honestBonusInterface);
        honestFeeInterface = IHonestFee(_honestFeeInterface);
        bAssetValidator = IBAssetValidator(_bAssetValidator);

        ERC20Mintable(address(this)).addMinter(_honestBasketInterface);
    }

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
        uint256 quantityTransferred = HAssetHelpers.transferTokens(msg.sender, _getBasketAddress(), _bAsset, false, _bAssetQuantity);
        // calc weight
        // query usd price for bAsset
        (uint256 bAssetPrice, uint256 bAssetPriceDecimals) = bAssetPriceInterface.getBAssetPrice(_bAsset);
        uint256 redeemFeeRate = honestFeeInterface.redeemFeeRate();
        if (bAssetPrice > 0 && bAssetPriceDecimals > 0) {
            uint256 priceScale = 10 ** bAssetPriceDecimals;
            if (bAssetPrice > priceScale.add(redeemFeeRate.mulTruncate(priceScale))) {
                //                uint256 bonusWeightFactor = bAssetPrice.sub(priceScale.add(redeemFeeRate.mulTruncate(priceScale)));
                //                uint256 feeFactor = redeemFeeRate.mulTruncate(priceScale);
                //                bonusWeightFactor = bonusWeightFactor.sub(feeFactor);
                //                uint256 bonusWeight = bonusWeightFactor.mulTruncateScale(quantityTransferred, priceScale);
                //                if (bonusWeight > 0) {
                // add bonus weight
                //                honestBonusInterface.addBonus(_recipient, bonusWeightFactor.mulTruncateScale(quantityTransferred, priceScale));
                honestBonusInterface.addBonus(_recipient, bAssetPrice.sub(priceScale.add(redeemFeeRate.mulTruncate(priceScale))).mulTruncateScale(quantityTransferred, priceScale));
                //                }
            }
        }

        // Mint the HAsset
        _mint(_recipient, quantityTransferred);
        emit Minted(msg.sender, _recipient, quantityTransferred, _bAsset, quantityTransferred);

        return quantityTransferred;
    }

    /** @dev Mint Multi */
    function _mintTo(address[] memory _bAssets, uint256[] memory _bAssetQuantities, address _recipient)
    internal
    returns (uint256 hAssetQuantity)
    {
        require(_recipient != address(0), "Must be a valid recipient");
        //        uint256 len = _bAssetQuantities.length;
        require(_bAssetQuantities.length > 0 && _bAssetQuantities.length == _bAssets.length, "Input array mismatch");

        (bool bAssetExist, uint8[] memory statuses) = honestBasketInterface.getBAssetsStatus(_bAssets);
        require(bAssetExist, "bAsset not exist in the Basket!");

        // Load only needed bAssets in array
        (bool mintValid, string memory reason) = bAssetValidator.validateMintMulti(_bAssets, statuses, _bAssetQuantities);
        require(mintValid, reason);

        uint256[] memory quantityTransferred = new  uint256[](_bAssetQuantities.length);
        for (uint256 i = 0; i < _bAssetQuantities.length; i++) {
            if (_bAssetQuantities[i] > 0) {
                // transfer bAsset to basket
                quantityTransferred[i] = HAssetHelpers.transferTokens(msg.sender, _getBasketAddress(), _bAssets[i], false, _bAssetQuantities[i]);
                hAssetQuantity = hAssetQuantity.add(quantityTransferred[i]);
            }
        }
        require(hAssetQuantity > 0, "No hAsset quantity to mint");

        // Mint the HAsset
        _mint(_recipient, hAssetQuantity);
        emit MintedMulti(msg.sender, _recipient, hAssetQuantity, _bAssets, _bAssetQuantities);

        _addMintBonus(_bAssets, quantityTransferred, _recipient);

        return hAssetQuantity;
    }

    function _addMintBonus(address[] memory _bAssets, uint256[] memory _bAssetQuantities, address _recipient) internal {
        require(_recipient != address(0), "Must be a valid recipient");
        require(_bAssetQuantities.length > 0 && _bAssetQuantities.length == _bAssets.length, "Input array mismatch");
        // query latest bAsset price
        (uint256[] memory prices, uint256[] memory decimals) = bAssetPriceInterface.getBAssetsPrice(_bAssets);
        require(_bAssets.length == prices.length, "bAsset price array count mismatch");
        uint256 redeemFeeRate = honestFeeInterface.redeemFeeRate();
        uint256 priceScale = 1;
        uint256 totalBonusWeight = 0;
        for (uint256 i = 0; i < _bAssets.length; i++) {
            if (_bAssetQuantities[i] > 0 && prices[i] > 0 && decimals[i] > 0) {
                if (decimals[i] < 18) {
                    priceScale = 10 ** (18 - decimals[i]);
                }
                if (prices[i].mulTruncate(priceScale) > (HonestMath.getFullScale().add(redeemFeeRate))) {// scale to 1e18
                    //                        uint256 bonusWeightFactor = prices[i].sub(priceScale).sub(redeemFeeRate.mulTruncate(priceScale));
                    //                        if (bonusWeightFactor > 0) {
                    //                            bonusWeightFactor = bonusWeightFactor.sub(redeemFeeRate.mulTruncate(priceScale));
                    //                        if (bonusWeightFactor > 0) {
                    //                        totalBonusWeight.add(bonusWeightFactor.mulTruncateScale(quantityTransferred, priceScale));
                    totalBonusWeight.add((prices[i].mulTruncate(priceScale).sub(HonestMath.getFullScale().add(redeemFeeRate))).mulTruncate(_bAssetQuantities[i]));
                    //                    totalBonusWeight.add(prices[i].sub(priceScale).sub(redeemFeeRate.mulTruncate(priceScale)).mulTruncateScale(quantityTransferred, priceScale));
                    //                        }
                    //                        }
                }
            }
        }

        // add bonus weight
        if (totalBonusWeight > 0) {
            honestBonusInterface.addBonus(_recipient, totalBonusWeight);
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
    function redeem(address _bAsset, uint256 _bAssetQuantity)
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
    function redeemTo(address _bAsset, uint256 _bAssetQuantity, address _recipient)
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
     * @return hAssetRedeemed     Relative number of hAsset units burned to pay for the bAssets
     */
    function redeemMulti(address[] calldata _bAssets, uint256[] calldata _bAssetQuantities)
    external
    nonReentrant
    returns (uint256 hAssetRedeemed)
    {
        return _redeemTo(_bAssets, _bAssetQuantities, msg.sender, false);
    }

    /**
     * @dev Credits a recipient with a certain quantity of selected bAssets, in exchange for burning the
     *      relative HAsset quantity from the sender. Sender also incurs a small fee, if any.
     * @param _bAssets          Address of the bAssets to redeem
     * @param _bAssetQuantities Units of the bAssets to redeem
     * @param _recipient        Address to credit with withdrawn bAssets
     * @return hAssetRedeemed     Relative number of hAsset units burned to pay for the bAssets
     */
    function redeemMultiTo(address[] calldata _bAssets, uint256[] calldata _bAssetQuantities, address _recipient)
    external
    nonReentrant
    returns (uint256 hAssetRedeemed)
    {
        return _redeemTo(_bAssets, _bAssetQuantities, _recipient, false);
    }

    function redeemMultiInProportion(uint256 _bAssetQuantity)
    external
    nonReentrant
    returns (uint256 hAssetRedeemed)
    {
        return _redeemToInProportion(_bAssetQuantity, msg.sender);
    }

    function redeemMultiInProportionTo(uint256 _bAssetQuantity, address _recipient)
    external
    nonReentrant
    returns (uint256 hAssetRedeemed)
    {
        return _redeemToInProportion(_bAssetQuantity, _recipient);
    }

    /***************************************
              REDEMPTION (INTERNAL)
    ****************************************/

    /** @dev Casting to arrays for use in redeemMulti func */
    function _redeemTo(address _bAsset, uint256 _bAssetQuantity, address _recipient)
    internal
    returns (uint256 hAssetRedeemed){
        address[] memory bAssets = new address[](1);
        uint256[] memory quantities = new uint256[](1);
        bAssets[0] = _bAsset;
        quantities[0] = _bAssetQuantity;
        return _redeemTo(bAssets, quantities, _recipient, false);
    }

    function _redeemToInProportion(uint256 _bAssetQuantity, address _recipient)
    internal
    returns (uint256 hAssetRedeemed){
        require(_bAssetQuantity > 0, "Must redeem some bAssets");
        require(_recipient != address(0), "Must be a valid recipient");

        (address[] memory allBAssets, uint8[] memory statuses) = honestBasketInterface.getBasket();
        address[] memory bAssets = bAssetValidator.filterValidBAsset(allBAssets, statuses);

        require(bAssets.length > 0, "No valid bAssets");
        uint len = bAssets.length;
        (uint256 sumBalance, uint256[] memory bAssetBalances) = honestBasketInterface.getBAssetsBalance(bAssets);
        require(bAssets.length == bAssetBalances.length, "Query bAsset balance failed");
        // calc bAssets quantity in Proportion

        uint256[] memory bAssetQuantities = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            uint256 quantity = _bAssetQuantity.mul(bAssetBalances[i]);
            bAssetQuantities[i] = quantity.div(sumBalance);
        }

        return _handleRedeem(bAssets, bAssetQuantities, bAssetBalances, _recipient, true);
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
        (uint256 sumBalance, uint256[] memory bAssetBalances) = honestBasketInterface.getBAssetsBalance(_bAssets);
        require(len == bAssetBalances.length, "Query bAsset balance failed");

        return _handleRedeem(_bAssets, _bAssetQuantities, bAssetBalances, _recipient, _inProportion);
    }

    function _handleRedeem(
        address[] memory _bAssets,
        uint256[] memory _bAssetQuantities,
        uint256[] memory _bAssetBalances,
        address _recipient,
        bool _inProportion
    )
    internal
    returns (uint256 hAssetQuantity)
    {
        // Redemption fee
        uint256 feeRate = 0;
        if (!_inProportion) {
            feeRate = honestFeeInterface.redeemFeeRate();
        }
        uint256 totalFee = 0;
        for (uint256 i = 0; i < _bAssetQuantities.length; i++) {
            require(_bAssetQuantities[i] <= _bAssetBalances[i], "Cannot redeem more bAsset than balance");
            hAssetQuantity = hAssetQuantity.add(_bAssetQuantities[i]);
            if (feeRate > 0) {
                totalFee.add(_bAssetQuantities[i].mulTruncate(feeRate));

                emit PaidFee(msg.sender, _bAssets[i], _bAssetQuantities[i].mulTruncate(feeRate));
            }
        }
        require(hAssetQuantity > 0, "Must redeem some bAssets");

        // Apply fees, burn hAsset and return bAsset to recipient
        _burn(msg.sender, hAssetQuantity);

        if (totalFee > 0) {
            // handle fee
            // trans hAsset fee to fee contract
            //            uint256 feeTransferred =
            HAssetHelpers.transferTokens(_getBasketAddress(), address(honestFeeInterface), address(this), false, totalFee);
        }


        emit Redeemed(msg.sender, _recipient, hAssetQuantity, _bAssets, _bAssetQuantities);
        return hAssetQuantity;
    }

    function _redeemFromBasket(address[] memory _bAssets, uint256[] memory _bAssetQuantities, uint256[] memory _bAssetBalances, address _recipient, uint256 _feeRate) internal {
        uint256 supplyBackToSaving = 0;
        uint256[] memory gapQuantities = new uint256[](_bAssetQuantities.length);
        address[] memory borrowBAssets = new address[](_bAssetQuantities.length);
        uint256 borrowBAssetsIndex = 0;
        uint256 quantityMinusFee = 0;
        for (uint256 i = 0; i < _bAssetQuantities.length; i++) {
            quantityMinusFee = _bAssetQuantities[i];
            // handle redeem fee
            //            (uint256 fee, uint256 outputMinusFee) = _deductRedeemFee(_bAssets[i], _bAssetQuantities[i], feeRate);
            if (_feeRate > 0) {
                quantityMinusFee = _bAssetQuantities[i].sub(_bAssetQuantities[i].mulTruncate(_feeRate));
            }
            //            uint256 quantityTransferred = HAssetHelpers.transferTokens(_getBasketAddress(), _recipient, _bAssets[i], false, HonestMath.min(outputMinusFee, _bAssetBalances[i]));
            // TODO quantityTransferred check
            if (quantityMinusFee <= _bAssetBalances[i]) {
                // pool balance enough
                HAssetHelpers.transferTokens(_getBasketAddress(), _recipient, _bAssets[i], false, quantityMinusFee);
            } else {
                // pool balance not enough
                HAssetHelpers.transferTokens(_getBasketAddress(), _recipient, _bAssets[i], false, _bAssetBalances[i]);
                gapQuantities[borrowBAssetsIndex] = quantityMinusFee.sub(_bAssetBalances[i]);
                supplyBackToSaving.add(gapQuantities[borrowBAssetsIndex]);
                borrowBAssets[borrowBAssetsIndex] = _bAssets[i];
                borrowBAssetsIndex = borrowBAssetsIndex.add(1);
            }
        }

        if (supplyBackToSaving > 0) {
            _swapWithSaving(borrowBAssets, gapQuantities, supplyBackToSaving);
        }
    }

    /** @dev swap bAsset with saving */
    function _swapWithSaving(address[] memory _borrowBAssets, uint256[] memory _gapQuantities, uint256 _supplyBackToSaving) internal {
        require(_supplyBackToSaving > 0, "Invalid supply quantity");
        require(_borrowBAssets.length > 0 && _borrowBAssets.length == _gapQuantities.length, "Input array mismatch");
        (address[] memory allBAssets, uint8[] memory statuses) = honestBasketInterface.getBasket();
        address[] memory allValidBAssets = bAssetValidator.filterValidBAsset(allBAssets, statuses);
        require(allValidBAssets.length > 0, "No valid bAsset in basket");
        uint256[] memory supplies = new uint256[](allValidBAssets.length);
        // query valid bAssets balance
        (uint256 sumBalance, uint256[] memory bAssetBalances) = honestBasketInterface.getBAssetsBalance(allValidBAssets);
        for (uint256 i = 0; i < allValidBAssets.length; i++) {
            supplies[i] = bAssetBalances[i].mul(_supplyBackToSaving).div(sumBalance);
        }
        honestSavingsInterface.swap(msg.sender, _borrowBAssets, _gapQuantities, allValidBAssets, supplies);
    }


    /***************************************
                    INTERNAL
    ****************************************/

    /**
      * @dev Gets the address of the BasketManager for this hAsset
      * @return HonestBasket contract Address
      */
    function _getBasketAddress()
    public
    view
    returns (address)
    {
        return address(honestBasketInterface);
    }

}
