pragma solidity ^0.5.0;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Initializable} from "@openzeppelin/upgrades/contracts/Initializable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Detailed} from '@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol';
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import {InitializablePausableModule} from "../common/InitializablePausableModule.sol";
import {InitializableReentrancyGuard} from "../common/InitializableReentrancyGuard.sol";
import {IHonestBasket} from "../interfaces/IHonestBasket.sol";
import {IHAsset} from "../interfaces/IHAsset.sol";
import {IHonestSavings} from "../interfaces/IHonestSavings.sol";
import {IHonestFee} from "../interfaces/IHonestFee.sol";
import {StandardERC20} from "../util/StandardERC20.sol";
import {HAssetHelpers} from "../util/HAssetHelpers.sol";
import {IBAssetValidator} from "../validator/IBAssetValidator.sol";
import {HonestMath} from "../util/HonestMath.sol";

contract HonestBasket is
Initializable,
IHonestBasket,
InitializablePausableModule,
InitializableReentrancyGuard {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using HonestMath for uint256;
    using StandardERC20 for ERC20Detailed;

    event Swapped(address indexed swapper, address input, address output, uint256 outputAmount, address recipient);
    event PaidFee(address indexed payer, address asset, uint256 feeQuantity);

    // Events for Basket composition changes
    event BassetAdded(address indexed bAsset, uint8 bAssetIndex);
    event BassetStatusChanged(address indexed bAsset, uint8 status);

    address public hAsset;

    address[] public bAssets;
    uint8 private maxBassets;
    uint8[] bAssetStatus;
    // Mapping holds bAsset token address => array index
    mapping(address => uint8) private bAssetsMap;
    mapping(address => uint8) private bAssetStatusMap;

    IHonestSavings private honestSavingsInterface;
    IHonestFee private honestFeeInterface;
    IBAssetValidator private bAssetValidator;
    IHAsset private hAssetInterface;

    function initialize(
        address _nexus,
        address _hAsset,
        address[] calldata _bAssets,
        address _honestSavingsInterface,
        address _honestFeeInterface,
        address _bAssetValidator
    )
    external
    initializer
    {
        InitializableReentrancyGuard._initialize();
        InitializablePausableModule._initialize(_nexus);

        require(_hAsset != address(0), "hAsset address is zero");
        require(_bAssets.length > 0, "Must initialise with some bAssets");
        hAsset = _hAsset;

        hAssetInterface = IHAsset(_hAsset);
        honestSavingsInterface = IHonestSavings(_honestSavingsInterface);
        honestFeeInterface = IHonestFee(_honestFeeInterface);
        bAssetValidator = IBAssetValidator(_bAssetValidator);

        // Defaults
        maxBassets = uint8(20);

        for (uint256 i = 0; i < _bAssets.length; i++) {
            _addBasset(_bAssets[i], uint8(0));
        }
    }


    //    function getBalance(address _bAsset) external view returns (uint256 balance){
    //        return _getBalance(_bAsset);
    //    }

    function _getBalance(address _bAsset) internal view returns (uint256 balance){
        require(_bAsset != address(0), "bAsset address must be valid");
        (bool exist, uint8 index) = _isAssetInBasket(_bAsset);
        require(exist, "bAsset not exist");

        balance = ERC20Detailed(_bAsset).standardBalanceOf(address(this));

        address[] memory _bAssets = new address[](1);
        _bAssets[0] = _bAsset;
        uint256[] memory bAssetBalances = honestSavingsInterface.investmentOf(_bAssets);
        if (bAssetBalances.length > 0) {
            balance = balance.add(bAssetBalances[0]);
        }
    }

    /** @dev Basket balance value of each bAsset */
    function getBAssetsBalance(address[] calldata _bAssets)
    external view
    returns (uint256 sumBalance, uint256[] memory balances){
        return _getBAssetsBalance(_bAssets);
    }

    function _getBAssetsBalance(address[] memory _bAssets)
    internal view
    returns (uint256 sumBalance, uint256[] memory balances){
        require(_bAssets.length > 0, "bAsset address must be valid");

        sumBalance = 0;
        uint256[] memory bAssetBalances = honestSavingsInterface.investmentOf(_bAssets);
        for (uint256 i = 0; i < _bAssets.length; i++) {
            (bool exist, uint8 index) = _isAssetInBasket(_bAssets[i]);

            if (exist) {
                uint256 poolBalance = ERC20Detailed(_bAssets[i]).standardBalanceOf(address(this));
                bAssetBalances[i] = bAssetBalances[i].add(poolBalance);
                sumBalance = sumBalance.add(bAssetBalances[i]);
            }
        }
        balances = bAssetBalances;
    }

    function getBasketAllBalance() external view returns (uint256 sumBalance, address[] memory allBAssets, uint256[] memory balances){
        allBAssets = bAssets;
        (sumBalance, balances) = _getBAssetsBalance(allBAssets);
    }

    /** @dev Basket all bAsset info */
    function getBasket()
    external view
    returns (address[] memory allBAssets, uint8[] memory statuses){
        return _getBasket();
    }

    function _getBasket()
    internal view
    returns (address[] memory allBAssets, uint8[] memory statuses){
        allBAssets = bAssets;
        statuses = new uint8[](bAssets.length);
        for (uint256 i = 0; i < bAssets.length; i++) {
            statuses[i] = bAssetStatusMap[bAssets[i]];
        }
    }

    function _getValidBAssets()
    internal view
    returns (address[] memory validBAssets){
        uint8[] memory statuses = new uint8[](bAssets.length);
        for (uint8 i = 0; i < bAssets.length; i++) {
            statuses[i] = bAssetStatusMap[bAssets[i]];
        }
        return bAssetValidator.filterValidBAsset(bAssets, statuses);
    }

    /** @dev query bAsset info */
    function getBAssetStatus(address _bAsset) external returns (bool, uint8){
        require(_bAsset != address(0), "bAsset address must be valid");
        (bool exist, uint8 index) = _isAssetInBasket(_bAsset);
        uint8 status = 0;
        if (exist) {
            status = bAssetStatusMap[_bAsset];
        }
        return (exist, status);
    }

    /** @dev query bAssets info */
    function getBAssetsStatus(address[] calldata _bAssets) external returns (bool, uint8[] memory){
        return _getBAssetsStatus(_bAssets);
    }

    function _getBAssetsStatus(address[] memory _bAssets) internal returns (bool, uint8[] memory){
        require(_bAssets.length > 0, "bAsset address must be valid");
        bool allExist = true;
        uint8[] memory statuses = new uint8[](_bAssets.length);
        for (uint256 i = 0; i < _bAssets.length; i++) {
            (bool exist, uint8 index) = _isAssetInBasket(_bAssets[i]);
            if (exist) {
                statuses[i] = bAssetStatusMap[_bAssets[i]];
            } else {
                allExist = false;
                break;
            }
        }
        return (allExist, statuses);
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
    function swap(address _input, address _output, uint256 _quantity, address _recipient)
    external
    nonReentrant
    returns (uint256 outputQuantity)
    {
        require(_input != address(0) && _output != address(0), "Invalid swap asset addresses");
        require(_input != _output, "Cannot swap the same asset");
        require(_recipient != address(0), "Missing recipient address");
        require(_output != hAsset, "Cannot swap hAsset");
        require(_quantity > 0, "Invalid quantity");

        // valid target bAssets
        address[] memory swapBAssets = new address[](2);
        swapBAssets[0] = _input;
        swapBAssets[1] = _output;
        (bool bAssetExist, uint8[] memory statuses) = _getBAssetsStatus(swapBAssets);
        require(bAssetExist, "BAsset not exist in the Basket!");

        (bool swapValid, string memory reason) = bAssetValidator.validateSwap(_input, statuses[0], _output, statuses[1], _quantity);
        require(swapValid, reason);

        // transfer bAsset to basket
        uint256 quantitySwapIn = HAssetHelpers.transferTokens(msg.sender, address(this), _input, false, _quantity);

        // check output bAsset balance
        uint256 standardQuantity = ERC20Detailed(_input).standardize(quantitySwapIn);
        uint256 bAssetPoolBalance = ERC20Detailed(_output).standardBalanceOf(address(this));
        require(standardQuantity <= bAssetPoolBalance, "Not enough swap out bAsset");

        // Deduct the swap fee, if any
        (uint256 swapFee, uint256 outputMinusFee) = _deductSwapFee(_output, standardQuantity, honestFeeInterface.swapFeeRate());

        outputQuantity = HAssetHelpers.transferTokens(address(this), _recipient, _output, false, ERC20Detailed(_output).resume(HonestMath.min(outputMinusFee, bAssetPoolBalance)));
        // handle swap fee, mint hAsset ,save to fee contract
        hAssetInterface.mintFee(address(honestFeeInterface), swapFee);

        if (outputMinusFee > bAssetPoolBalance) {
            // pool balance not enough
            _supplyBackToSaving(_output, outputMinusFee.sub(bAssetPoolBalance));
        }
        emit Swapped(msg.sender, _input, _output, outputQuantity, _recipient);
    }

    function _supplyBackToSaving(address _bAsset, uint256 _quantity) internal {
        address[] memory borrowBAssets = new address[](1);
        borrowBAssets[0] = _bAsset;
        uint256[] memory borrows = new uint256[](1);
        borrows[0] = _quantity;
        // calc bAsset supplies to saving
        address[] memory allValidBAssets = _getValidBAssets();
        uint256[] memory supplies = new uint256[](allValidBAssets.length);
        (uint256 sumBalance, uint256[] memory bAssetBalances) = _getBAssetBasketBalance(allValidBAssets);
        for (uint256 i = 0; i < allValidBAssets.length; i++) {
            supplies[i] = bAssetBalances[i].mul(_quantity).div(sumBalance);
        }
        // barrow gap quantity from saving, saving will send bAsset to msg.sender
        honestSavingsInterface.swap(msg.sender, borrowBAssets, borrows, allValidBAssets, supplies);
    }

    /**
     * @dev Determines both if a trade is valid, and the expected fee or output.
     * Swap is valid if it does not result in the input asset exceeding its maximum weight.
     * @param _input        bAsset to deposit
     * @param _output       Asset to receive - bAsset or hAsset(this)
     * @param _quantity     Units of input bAsset to swap
     * @return valid        Bool to signify that swap is current valid
     * @return reason       If swap is invalid, this is the reason
     * @return outputQuantity       Units of _output asset the trade would return
     */
    function getSwapOutput(address _input, address _output, uint256 _quantity)
    external
    returns (bool, string memory, uint256 outputQuantity)
    {
        require(_input != address(0) && _output != address(0), "Invalid swap asset addresses");
        require(_input != _output, "Cannot swap the same asset");
        require(_output != hAsset, "Cannot swap hAsset");

        //        bool isMint = (_output == address(this));
        uint256 quantity = ERC20Detailed(_input).standardize(_quantity);

        // valid target bAssets
        address[] memory bAssets = new address[](2);
        bAssets[0] = _input;
        bAssets[1] = _output;
        (bool bAssetExist, uint8[] memory statuses) = _getBAssetsStatus(bAssets);
        require(bAssetExist, "BAsset not exist in the Basket!");

        // 2. check if trade is valid
        (bool swapValid, string memory reason) = bAssetValidator.validateSwap(_input, statuses[0], _output, statuses[1], _quantity);
        if (!swapValid) {
            return (false, reason, 0);
        }
        uint256 swapFeeRate = honestFeeInterface.swapFeeRate();
        if (swapFeeRate > 0) {
            uint256 swapFee = quantity.mulTruncate(swapFeeRate);
            quantity = quantity.sub(swapFee);
        }
        outputQuantity = ERC20Detailed(_output).resume(quantity);
        return (true, "", outputQuantity);
    }

    /** @dev Setters for Gov to update Basket composition */
    function addBAsset(address _bAsset, uint8 _status)
    external
    onlyGovernor
    nonReentrant
    returns (uint8 index){
        index = _addBasset(_bAsset, _status);
    }

    function _addBasset(address _bAsset, uint8 _status)
    internal
    returns (uint8 index)
    {
        require(_bAsset != address(0), "bAsset address must be valid");

        (bool alreadyInBasket,) = _isAssetInBasket(_bAsset);
        require(!alreadyInBasket, "bAsset already exists in Basket");

        uint8 numberOfBassetsInBasket = uint8(bAssets.length);
        require(numberOfBassetsInBasket < maxBassets, "Max bAssets in Basket");

        bAssets.push(_bAsset);
        bAssetStatus.push(_status);
        bAssetStatusMap[_bAsset] = _status;
        bAssetsMap[_bAsset] = numberOfBassetsInBasket;

        emit BassetAdded(_bAsset, numberOfBassetsInBasket);

        index = numberOfBassetsInBasket;
    }

    /**
     * @dev Checks if a particular asset is in the basket
     */
    function _isAssetInBasket(address _bAsset)
    internal
    view
    returns (bool exists, uint8 index)
    {
        index = bAssetsMap[_bAsset];
        if (index == 0) {
            if (bAssets.length == 0) {
                return (false, 0);
            }
            return (bAssets[0] == _bAsset, 0);
        }
        return (true, index);
    }

    function updateBAssetStatus(address _bAsset, uint8 _newStatus)
    external
    onlyGovernor
    returns (uint8 index)
    {
        (bool exists, uint256 i) = _isAssetInBasket(_bAsset);
        require(exists, "bAsset must exist");

        if (_newStatus != bAssetStatusMap[_bAsset]) {
            bAssetStatusMap[_bAsset] = _newStatus;
            bAssetStatus[i] = _newStatus;
            emit BassetStatusChanged(_bAsset, _newStatus);
        }
    }

    // TODO: delete _integration
    function swapBAssets(address _integration, uint256 _totalAmount, address[] calldata _expectAssets)
    external
    returns (uint256[] memory) {
        require(_integration != address(0), "integration address must be valid");
        require(_totalAmount > 0, "amount must greater than 0");
        uint256 length = _expectAssets.length;
        require(length > 0, "assets length must greater than 0");

        (uint256[] memory percentages, uint256 totalBalance) = _getBalancePercentages(_expectAssets);
        require(_totalAmount <= totalBalance, "insufficient balance");

        uint256[] memory amounts = new uint256[](length);
        for (uint256 i = 0; i < length; ++i) {
            amounts[i] = _totalAmount.mul(percentages[i]).div(uint256(1e18));
            ERC20Detailed(_expectAssets[i]).standardTransfer(msg.sender, amounts[i]);
        }
        return amounts;
    }

    function distributeHAssets(address _account, address[] calldata _bAssets, uint256[] calldata _amounts, uint256 _interests)
    external {
        require(_account != address(0), "Saver address must be valid");
        require(_bAssets.length > 0 && _bAssets.length == _amounts.length, "BAssets array mismatch ");

        uint256 hUSDReturn = 0;
        // trans bAsset back to basket from saving
        for (uint256 i = 0; i < _bAssets.length; i++) {
            if (_amounts[i] > 0) {
                uint256 quantityBAssetBack = HAssetHelpers.transferTokens(msg.sender, address(this), _bAssets[i], false, _amounts[i]);
                hUSDReturn = hUSDReturn.add(_amounts[i]);
            }
        }

        if (_interests > 0) {// mint interests to basket
            hAssetInterface.mintFee(address(this), _interests);
        }

        // trans hUSD(saving quantity + interests) back to saver
        uint256 quantityHUSDBack = HAssetHelpers.transferTokens(address(this), _account, hAsset, false, hUSDReturn);

    }

    function _getBalancePercentages(address[] memory _bAssets)
    internal view
    returns (uint256[] memory, uint256) {
        uint256 length = _bAssets.length;
        uint256[] memory percentages = new uint256[](length);
        uint256 totalBalances;
        for (uint256 i = 0; i < length; ++i) {
            uint256 balance = ERC20Detailed(_bAssets[i]).standardBalanceOf(address(this));
            percentages[i] = balance;
            totalBalances = totalBalances.add(balance);
        }
        for (uint256 i = 0; i < length; ++i) {
            percentages[i] = percentages[i].mul(uint256(1e18)).div(totalBalances);
        }
        return (percentages, totalBalances);
    }

    /**
     * @dev Pay the swap fee
     */
    function _deductSwapFee(address _asset, uint256 _bAssetQuantity, uint256 _feeRate)
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

    function _getBAssetBasketBalance(address[] memory _bAssets)
    internal
    returns (uint256 sumBalance, uint256[] memory bAssetBalances){
        require(_bAssets.length > 0, "No invalid bAssets");
        sumBalance = 0;
        for (uint256 i = 0; i < _bAssets.length; i++) {
            bAssetBalances[i] = ERC20Detailed(_bAssets[i]).standardBalanceOf(address(this));
            sumBalance = sumBalance.add(bAssetBalances[i]);
        }
    }
}
