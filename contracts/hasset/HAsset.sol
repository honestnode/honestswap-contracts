pragma solidity ^0.5.0;
//
//// Libs
//import {Initializable} from "@openzeppelin/upgrades/contracts/Initializable.sol";
//import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
//import {ERC20Detailed} from '@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol';
//import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
//
//import {InitializableToken} from "../common/InitializableToken.sol";
//import {InitializableModule} from "../common/InitializableModule.sol";
//import {InitializableReentrancyGuard} from "../common/InitializableReentrancyGuard.sol";
//import {IHAsset} from "../interfaces/IHAsset.sol";
//import {IHonestBasket} from "../interfaces/IHonestBasket.sol";
//import {IHonestSavings} from "../interfaces/IHonestSavings.sol";
//import {IHonestBonus} from "../interfaces/IHonestBonus.sol";
//import {IHonestFee} from "../interfaces/IHonestFee.sol";
//import {IBAssetValidator} from "../validator/IBAssetValidator.sol";
//import {IPlatformIntegration} from "../interfaces/IPlatformIntegration.sol";
//import {HAssetHelpers} from "../util/HAssetHelpers.sol";
//import {HonestMath} from "../util/HonestMath.sol";
//import {StandardERC20} from "../util/StandardERC20.sol";
//
//contract HAsset is
//Initializable,
//IHAsset,
//InitializableToken,
//InitializableModule,
//InitializableReentrancyGuard {
//
//    using SafeMath for uint256;
//    using HonestMath for uint256;
//    using StandardERC20 for ERC20Detailed;
//
//    // Forging Events
//    event Minted(address indexed minter, address recipient, uint256 hAssetQuantity, address bAsset, uint256 bAssetQuantity);
//    event MintedMulti(address indexed minter, address recipient, uint256 hAssetQuantity, address[] bAssets, uint256[] bAssetQuantities);
//
//    event Redeemed(address indexed redeemer, address recipient, uint256 hAssetQuantity, address[] bAssets, uint256[] bAssetQuantities);
//    event RedeemedHAsset(address indexed redeemer, address recipient, uint256 hAssetQuantity);
//    event PaidFee(address indexed payer, address asset, uint256 feeQuantity);
//
//    // State Events
//    event RedemptionFeeChanged(uint256 fee);
//
//    IHonestBasket private honestBasketInterface;
//    IHonestBonus private honestBonusInterface;
//    IHonestFee private honestFeeInterface;
//    IHonestSavings private honestSavingsInterface;
//    IBAssetValidator private bAssetValidator;
//
//    /**
//     * @dev Constructor
//     * @notice To avoid variable shadowing appended `Arg` after arguments name.
//     */
//    function initialize(
//        string calldata _nameArg,
//        string calldata _symbolArg,
//        address _nexus,
//        address _honestBasketInterface,
//        address _honestSavingsInterface,
//        address _honestBonusInterface,
//        address _honestFeeInterface,
//        address _bAssetValidator
//    )
//    external
//    initializer
//    {
//        InitializableToken._initialize(_nameArg, _symbolArg);
//        InitializableModule._initialize(_nexus);
//        InitializableReentrancyGuard._initialize();
//
//        honestBasketInterface = IHonestBasket(_honestBasketInterface);
//        honestSavingsInterface = IHonestSavings(_honestSavingsInterface);
//        honestBonusInterface = IHonestBonus(_honestBonusInterface);
//        honestFeeInterface = IHonestFee(_honestFeeInterface);
//        bAssetValidator = IBAssetValidator(_bAssetValidator);
//    }
//
//    /**
//     * @dev Mint a single hAsset, at a 1:1 ratio with the bAsset. This contract
//     *      must have approval to spend the senders bAsset
//     * @param _bAsset         Address of the bAsset to mint
//     * @param _bAssetQuantity Quantity in bAsset units
//     * @return hAssetMinted   Number of newly minted hAssets
//     */
//    //    function mint(address _bAsset, uint256 _bAssetQuantity)
//    //    external
//    //    nonReentrant
//    //    returns (uint256 hAssetMinted)
//    //    {
//    //        return _mintTo(_bAsset, _bAssetQuantity, msg.sender);
//    //    }
//
//    /**
//     * @dev Mint a single bAsset, at a 1:1 ratio with the bAsset. This contract
//     *      must have approval to spend the senders bAsset
//     * @param _bAsset         Address of the bAsset to mint
//     * @param _bAssetQuantity Quantity in bAsset units
//     * @param _recipient receipient of the newly minted mAsset tokens
//     * @return hAssetMinted   Number of newly minted hAssets
//     */
////    function mintTo(
////        address _bAsset,
////        uint256 _bAssetQuantity,
////        address _recipient
////    )
////    external
////    nonReentrant
////    returns (uint256 hAssetMinted)
////    {
////        return _mintTo(_bAsset, _bAssetQuantity, _recipient);
////    }
//
//
//    /**
//     * @dev Mint with multiple bAssets, at a 1:1 ratio to mAsset. This contract
//     *      must have approval to spend the senders bAssets
//     * @param _bAssets          Non-duplicate address array of bAssets with which to mint
//     * @param _bAssetQuantity   Quantity of each bAsset to mint. Order of array
//     *                          should mirror the above
//     * @return hAssetMinted     Number of newly minted hAssets
//     */
//    //    function mintMulti(address[] calldata _bAssets, uint256[] calldata _bAssetQuantity)
//    //    external
//    //    nonReentrant
//    //    returns (uint256 hAssetMinted)
//    //    {
//    //        return _mintTo(_bAssets, _bAssetQuantity, msg.sender);
//    //    }
//
//    /**
//     * @dev Mint with multiple bAssets, at a 1:1 ratio to mAsset. This contract
//     *      must have approval to spend the senders bAssets
//     * @param _bAssets          Non-duplicate address array of bAssets with which to mint
//     * @param _bAssetQuantity   Quantity of each bAsset to mint. Order of array
//     *                          should mirror the above
//     * @param _recipient        recipient of the newly minted mAsset tokens
//     * @return hAssetMinted     Number of newly minted hAssets
//     */
//    function mintMultiTo(address[] calldata _bAssets, uint256[] calldata _bAssetQuantity, address _recipient)
//    external
//    nonReentrant
//    returns (uint256 hAssetMinted)
//    {
//        return _mintTo(_bAssets, _bAssetQuantity, _recipient);
//    }
//
//    /***************************************
//              MINTING (INTERNAL)
//    ****************************************/
//
//    /** @dev Mint Single */
////    function _mintTo(
////        address _bAsset,
////        uint256 _bAssetQuantity,
////        address _recipient
////    )
////    internal
////    returns (uint256 hAssetMinted)
////    {
////        require(_recipient != address(0), "Must be a valid recipient");
////        require(_bAssetQuantity > 0, "Quantity must not be 0");
////
////        // check exist, get Basset detail
////        (bool bAssetExist, uint8 bAssetStatus) = honestBasketInterface.getBAssetStatus(_bAsset);
////        require(bAssetExist, "bAsset not exist in the Basket!");
////        // Validation
////        (bool mintValid, string memory reason) = bAssetValidator.validateMint(_bAsset, bAssetStatus, _bAssetQuantity);
////        require(mintValid, reason);
////
////        // transfer bAsset to basket
////        uint256 quantityTransferred = HAssetHelpers.transferTokens(msg.sender, _getBasketAddress(), _bAsset, false, _bAssetQuantity);
////        hAssetMinted = ERC20Detailed(_bAsset).standardize(quantityTransferred);
////        //        uint256 redeemFeeRate = honestFeeInterface.redeemFeeRate();
////        uint256 bonus = honestBonusInterface.calculateBonus(_bAsset, hAssetMinted, honestFeeInterface.redeemFeeRate());
////        if (bonus > 0) {
////            honestBonusInterface.addBonus(msg.sender, bonus);
////        }
////
////        // Mint the HAsset
////        _mint(_recipient, hAssetMinted);
////        emit Minted(msg.sender, _recipient, hAssetMinted, _bAsset, _bAssetQuantity);
////
////        return quantityTransferred;
////    }
//
//    /** @dev Mint Multi */
//    function _mintTo(address[] memory _bAssets, uint256[] memory _bAssetQuantities, address _recipient)
//    internal
//    returns (uint256 hAssetQuantity)
//    {
//        require(_recipient != address(0), "Must be a valid recipient");
//        //        uint256 len = _bAssetQuantities.length;
//        require(_bAssetQuantities.length > 0 && _bAssetQuantities.length == _bAssets.length, "Input array mismatch");
//
//        (bool bAssetExist, uint8[] memory statuses) = honestBasketInterface.getBAssetsStatus(_bAssets);
//        require(bAssetExist, "bAsset not exist in the Basket!");
//
//        // Load only needed bAssets in array
//        (bool mintValid, string memory reason) = bAssetValidator.validateMintMulti(_bAssets, statuses, _bAssetQuantities);
//        require(mintValid, reason);
//
//        (uint256 mintQuantity, uint256[] memory quantityTransferred) = _mintTrans(_bAssets, _bAssetQuantities);
//        require(mintQuantity > 0, "No hAsset quantity to mint");
//        hAssetQuantity = mintQuantity;
//        // Mint the HAsset
//        _mint(_recipient, hAssetQuantity);
//        emit MintedMulti(msg.sender, _recipient, hAssetQuantity, _bAssets, _bAssetQuantities);
//
//        _addMintBonus(_bAssets, quantityTransferred, _recipient);
//    }
//
//    function _mintTrans(address[] memory _bAssets, uint256[] memory _bAssetQuantities) internal returns (uint256 hAssetQuantity, uint256[] memory quantityTransferred){
//        for (uint256 i = 0; i < _bAssetQuantities.length; i++) {
//            if (_bAssetQuantities[i] > 0) {
//                // transfer bAsset to basket
//                quantityTransferred[i] = HAssetHelpers.transferTokens(msg.sender, _getBasketAddress(), _bAssets[i], false, _bAssetQuantities[i]);
//                quantityTransferred[i] = ERC20Detailed(_bAssets[i]).standardize(quantityTransferred[i]);
//                hAssetQuantity = hAssetQuantity.add(quantityTransferred[i]);
//            }
//        }
//    }
//
//    function _addMintBonus(address[] memory _bAssets, uint256[] memory _bAssetQuantities, address _recipient) internal {
//        require(_recipient != address(0), "Must be a valid recipient");
//        require(_bAssetQuantities.length > 0 && _bAssetQuantities.length == _bAssets.length, "Input array mismatch");
//
//        uint256 redeemFeeRate = honestFeeInterface.redeemFeeRate();
//        uint256 bonus = honestBonusInterface.calculateBonuses(_bAssets, _bAssetQuantities, redeemFeeRate);
//        if (bonus > 0) {
//            honestBonusInterface.addBonus(_recipient, bonus);
//        }
//    }
//
//    /***************************************
//              REDEMPTION (PUBLIC)
//    ****************************************/
//    /**
//     * @dev Credits the sender with a certain quantity of selected bAsset, in exchange for burning the
//     *      relative hAsset quantity from the sender. Sender also incurs a small hAsset fee, if any.
//     * @param _bAsset           Address of the bAsset to redeem
//     * @param _bAssetQuantity   Units of the bAsset to redeem
//     * @return hAssetRedeemed     Relative number of hAsset units burned to pay for the bAssets
//     */
//    //    function redeem(address _bAsset, uint256 _bAssetQuantity)
//    //    external
//    //    nonReentrant
//    //    returns (uint256 hAssetRedeemed)
//    //    {
//    //        return _redeemTo(_bAsset, _bAssetQuantity, msg.sender);
//    //    }
//
//    /**
//     * @dev Credits a recipient with a certain quantity of selected bAsset, in exchange for burning the
//     *      relative Hasset quantity from the sender. Sender also incurs a small fee, if any.
//     * @param _bAsset           Address of the bAsset to redeem
//     * @param _bAssetQuantity   Units of the bAsset to redeem
//     * @param _recipient        Address to credit with withdrawn bAssets
//     * @return hAssetRedeemed     Relative number of hAsset units burned to pay for the bAssets
//     */
////    function redeemTo(address _bAsset, uint256 _bAssetQuantity, address _recipient)
////    external
////    nonReentrant
////    returns (uint256 hAssetRedeemed)
////    {
////        return _redeemTo(_bAsset, _bAssetQuantity, _recipient);
////    }
//
//    /**
//     * @dev Credits a recipient with a certain quantity of selected bAssets, in exchange for burning the
//     *      relative HAsset quantity from the sender. Sender also incurs a small fee, if any.
//     * @param _bAssets          Address of the bAssets to redeem
//     * @param _bAssetQuantities Units of the bAssets to redeem
//     * @return hAssetRedeemed     Relative number of hAsset units burned to pay for the bAssets
//     */
//    //    function redeemMulti(address[] calldata _bAssets, uint256[] calldata _bAssetQuantities)
//    //    external
//    //    nonReentrant
//    //    returns (uint256 hAssetRedeemed)
//    //    {
//    //        return _redeemTo(_bAssets, _bAssetQuantities, msg.sender, false);
//    //    }
//
//    /**
//     * @dev Credits a recipient with a certain quantity of selected bAssets, in exchange for burning the
//     *      relative HAsset quantity from the sender. Sender also incurs a small fee, if any.
//     * @param _bAssets          Address of the bAssets to redeem
//     * @param _bAssetQuantities Units of the bAssets to redeem
//     * @param _recipient        Address to credit with withdrawn bAssets
//     * @return hAssetRedeemed     Relative number of hAsset units burned to pay for the bAssets
//     */
//    function redeemMultiTo(address[] calldata _bAssets, uint256[] calldata _bAssetQuantities, address _recipient)
//    external
//    nonReentrant
//    returns (uint256 hAssetRedeemed)
//    {
//        return _redeemTo(_bAssets, _bAssetQuantities, _recipient, false);
//    }
//
//    //    function redeemMultiInProportion(uint256 _bAssetQuantity)
//    //    external
//    //    nonReentrant
//    //    returns (uint256 hAssetRedeemed)
//    //    {
//    //        return _redeemToInProportion(_bAssetQuantity, msg.sender);
//    //    }
//
//    function redeemMultiInProportionTo(uint256 _bAssetQuantity, address _recipient)
//    external
//    nonReentrant
//    returns (uint256 hAssetRedeemed)
//    {
//        return _redeemToInProportion(_bAssetQuantity, _recipient);
//    }
//
//    /***************************************
//              REDEMPTION (INTERNAL)
//    ****************************************/
//
//    /** @dev Casting to arrays for use in redeemMulti func */
////    function _redeemTo(address _bAsset, uint256 _bAssetQuantity, address _recipient)
////    internal
////    returns (uint256 hAssetRedeemed){
////        address[] memory bAssets = new address[](1);
////        uint256[] memory quantities = new uint256[](1);
////        bAssets[0] = _bAsset;
////        quantities[0] = _bAssetQuantity;
////        return _redeemTo(bAssets, quantities, _recipient, false);
////    }
//
//    function _redeemToInProportion(uint256 _bAssetQuantity, address _recipient)
//    internal
//    returns (uint256 hAssetRedeemed){
//        require(_bAssetQuantity > 0, "Must redeem some bAssets");
//        require(_recipient != address(0), "Must be a valid recipient");
//
//        (address[] memory allBAssets, uint8[] memory statuses) = honestBasketInterface.getBasket();
//        address[] memory bAssets = bAssetValidator.filterValidBAsset(allBAssets, statuses);
//
//        require(bAssets.length > 0, "No valid bAssets");
//        //        uint len = bAssets.length;
//        (uint256 sumBalance, uint256[] memory bAssetBalances) = honestBasketInterface.getBAssetsBalance(bAssets);
//        require(bAssets.length == bAssetBalances.length, "Query bAsset balance failed");
//        // calc bAssets quantity in Proportion
//
//        uint256[] memory bAssetQuantities = new uint256[](bAssets.length);
//        for (uint256 i = 0; i < bAssets.length; i++) {
//            bAssetQuantities[i] = _bAssetQuantity.mul(bAssetBalances[i]).div(sumBalance);
//        }
//
//        return _handleRedeem(bAssets, bAssetQuantities, bAssetBalances, _recipient, true);
//    }
//
//    /** @dev Redeem hAsset for one or more bAssets */
//    function _redeemTo(
//        address[] memory _bAssets,
//        uint256[] memory _bAssetQuantities,
//        address _recipient,
//        bool _inProportion
//    )
//    internal
//    returns (uint256 hAssetRedeemed)
//    {
//        require(_recipient != address(0), "Must be a valid recipient");
//        require(_bAssets.length > 0 && _bAssets.length == _bAssetQuantities.length, "Input array mismatch");
//
//        // valid target bAssets
//        (bool bAssetExist, uint8[] memory statuses) = honestBasketInterface.getBAssetsStatus(_bAssets);
//        require(bAssetExist, "BAsset not exist in the Basket!");
//
//        // Load only needed bAssets in array
//        (bool redeemValid, string memory reason) = bAssetValidator.validateRedeem(_bAssets, statuses, _bAssetQuantities);
//        require(redeemValid, reason);
//
//        // query basket balance
//        (uint256 sumBalance, uint256[] memory bAssetBalances) = honestBasketInterface.getBAssetsBalance(_bAssets);
//        require(_bAssets.length == bAssetBalances.length, "Query bAsset balance failed");
//
//        return _handleRedeem(_bAssets, _bAssetQuantities, bAssetBalances, _recipient, _inProportion);
//    }
//
//    function _handleRedeem(
//        address[] memory _bAssets,
//        uint256[] memory _bAssetQuantities,
//        uint256[] memory _bAssetBalances,
//        address _recipient,
//        bool _inProportion
//    )
//    internal
//    returns (uint256 hAssetQuantity)
//    {
//        // Redemption fee
//        uint256 feeRate = 0;
//        if (!_inProportion) {
//            feeRate = honestFeeInterface.redeemFeeRate();
//        }
//        uint256 totalFee = 0;
//        uint256[] memory quantities = new uint256[](_bAssetQuantities.length);
//        uint256[] memory bAssetBasketBalances = new uint256[](_bAssetQuantities.length);
//        for (uint256 i = 0; i < _bAssetQuantities.length; i++) {
//            quantities[i] = ERC20Detailed(_bAssets[i]).standardize(_bAssetQuantities[i]);
//            require(quantities[i] <= bAssetBasketBalances[i], "Cannot redeem more bAsset than balance");
//            hAssetQuantity = hAssetQuantity.add(quantities[i]);
//
//            bAssetBasketBalances[i] = ERC20Detailed(_bAssets[i]).standardBalanceOf(_getBasketAddress());
//            if (feeRate > 0) {
//                totalFee.add(quantities[i].mulTruncate(feeRate));
//                // handle redeem fee
//                quantities[i] = quantities[i].sub(quantities[i].mulTruncate(feeRate));
//
//                emit PaidFee(msg.sender, _bAssets[i], _bAssetQuantities[i].mulTruncate(feeRate));
//            }
//        }
//        require(hAssetQuantity > 0, "Must redeem some bAssets");
//
//        // Apply fees, burn hAsset and return bAsset to recipient
//        _burn(msg.sender, hAssetQuantity);
//
//        if (totalFee > 0) {
//            // handle fee
//            // trans hAsset fee to fee contract
//            //            uint256 feeTransferred =
//            HAssetHelpers.transferTokens(_getBasketAddress(), address(honestFeeInterface), address(this), false, totalFee);
//        }
//
//        bool needSwap = _redeemFromBasket(_bAssets, quantities, bAssetBasketBalances, _recipient);
//        if (needSwap) {
//            _redeemSwap(_bAssets, quantities, bAssetBasketBalances);
//        }
//        emit Redeemed(msg.sender, _recipient, hAssetQuantity, _bAssets, _bAssetQuantities);
//    }
//
//    function _redeemFromBasket(address[] memory _bAssets, uint256[] memory _quantities, uint256[] memory _bAssetBasketBalances, address _recipient)
//    internal returns (bool needSwap){
//        uint256 redeemQyt = 0;
//        for (uint256 i = 0; i < _bAssets.length; i++) {
//            redeemQyt = _quantities[i];
//            if (_quantities[i] > _bAssetBasketBalances[i]) {
//                // pool balance not enough
//                redeemQyt = _bAssetBasketBalances[i];
//                needSwap = true;
//            }
//            // TODO quantityTransferred check
//            HAssetHelpers.transferTokens(_getBasketAddress(), _recipient, _bAssets[i], false, ERC20Detailed(_bAssets[i]).resume(redeemQyt));
//        }
//    }
//
//    function _redeemSwap(address[] memory _bAssets, uint256[] memory _quantities, uint256[] memory _bAssetBasketBalances) internal {
//        uint256 supplyBackToSaving = 0;
//        uint256[] memory gapQuantities = new uint256[](_bAssets.length);
//        address[] memory borrowBAssets = new address[](_bAssets.length);
//        uint256 borrowBAssetsIndex = 0;
//        uint256 quantityMinusFee = 0;
//        for (uint256 i = 0; i < _bAssets.length; i++) {
//            if (_quantities[i] > _bAssetBasketBalances[i]) {
//                // pool balance not enough
//                gapQuantities[borrowBAssetsIndex] = _quantities[i].sub(_bAssetBasketBalances[i]);
//                supplyBackToSaving.add(gapQuantities[borrowBAssetsIndex]);
//                borrowBAssets[borrowBAssetsIndex] = _bAssets[i];
//                borrowBAssetsIndex = borrowBAssetsIndex.add(1);
//            }
//        }
//
//        if (supplyBackToSaving > 0) {
//            _swapWithSaving(borrowBAssets, gapQuantities, supplyBackToSaving);
//        }
//    }
//
//    /** @dev swap bAsset with saving */
//    function _swapWithSaving(address[] memory _borrowBAssets, uint256[] memory _gapQuantities, uint256 _supplyBackToSaving) internal {
//        require(_supplyBackToSaving > 0, "Invalid supply quantity");
//        require(_borrowBAssets.length > 0 && _borrowBAssets.length == _gapQuantities.length, "Input array mismatch");
//        (address[] memory allBAssets, uint8[] memory statuses) = honestBasketInterface.getBasket();
//        address[] memory allValidBAssets = bAssetValidator.filterValidBAsset(allBAssets, statuses);
//        require(allValidBAssets.length > 0, "No valid bAsset in basket");
//        uint256[] memory supplies = new uint256[](allValidBAssets.length);
//        // query valid bAssets balance
//        (uint256 sumBalance, uint256[] memory bAssetBalances) = _getBAssetBasketBalance(allValidBAssets);
//        for (uint256 i = 0; i < allValidBAssets.length; i++) {
//            supplies[i] = bAssetBalances[i].mul(_supplyBackToSaving).div(sumBalance);
//        }
//        honestSavingsInterface.swap(msg.sender, _borrowBAssets, _gapQuantities, allValidBAssets, supplies);
//    }
//
//    function _getBAssetBasketBalance(address[] memory _bAssets)
//    internal
//    returns (uint256 sumBalance, uint256[] memory bAssetBalances){
//        sumBalance = 0;
//        for (uint256 i = 0; i < _bAssets.length; i++) {
//            bAssetBalances[i] = ERC20Detailed(_bAssets[i]).standardBalanceOf(_getBasketAddress());
//            sumBalance = sumBalance.add(bAssetBalances[i]);
//        }
//    }
//
//
//    /***************************************
//                    INTERNAL
//    ****************************************/
//
//    /**
//      * @dev Gets the address of the BasketManager for this hAsset
//      * @return HonestBasket contract Address
//      */
//    function _getBasketAddress()
//    public
//    view
//    returns (address)
//    {
//        return address(honestBasketInterface);
//    }
//
//    modifier onlyBasket() {
//        require(address(honestBasketInterface) == msg.sender, "Must be basket");
//        _;
//    }
//
//    function mintFee(address _recipient, uint256 _fee) external onlyBasket returns (uint256 hAssetMinted){
//        require(_recipient != address(0), "Recipient address must be valid");
//        require(_fee > 0, "Fee to mint must > 0");
//        _mint(_recipient, _fee);
//    }
//}
