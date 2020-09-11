pragma solidity ^0.5.0;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Initializable} from "@openzeppelin/upgrades/contracts/Initializable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Detailed} from '@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol';
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import {InitializablePausableModule} from "../common/InitializablePausableModule.sol";
import {InitializableReentrancyGuard} from "../common/InitializableReentrancyGuard.sol";
import {IHonestBasket} from "../interfaces/IHonestBasket.sol";
import {IHonestSavings} from "../interfaces/IHonestSavings.sol";
import {StandardERC20} from "../util/StandardERC20.sol";

contract HonestBasket is
Initializable,
IHonestBasket,
InitializablePausableModule,
InitializableReentrancyGuard {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using StandardERC20 for ERC20Detailed;

    // Events for Basket composition changes
    event BassetAdded(address indexed bAsset, uint8 bAssetIndex);
    event BassetStatusChanged(address indexed bAsset, uint8 status);

    address public hAsset;

    address[] private bAssets;
    uint8 private maxBassets;
    // Mapping holds bAsset token address => array index
    mapping(address => uint8) private bAssetsMap;
    mapping(address => uint8) private bAssetStatusMap;

    IHonestSavings private honestSavingsInterface;

    function initialize(
        address _nexus,
        address _hAsset,
        address[] calldata _bAssets,
        address _honestSavingsInterface
    )
    external
    initializer
    {
        InitializableReentrancyGuard._initialize();
        InitializablePausableModule._initialize(_nexus);

        require(_hAsset != address(0), "hAsset address is zero");
        require(_bAssets.length > 0, "Must initialise with some bAssets");
        hAsset = _hAsset;

        honestSavingsInterface = IHonestSavings(_honestSavingsInterface);

        // Defaults
        maxBassets = uint8(20);

        for (uint256 i = 0; i < _bAssets.length; i++) {
            _addBasset(_bAssets[i], uint8(0));
        }
    }

    modifier managerOrGovernor() {
        require(
            _manager() == msg.sender || _governor() == msg.sender,
            "Must be manager or governor");
        _;
    }

    function getBalance(address _bAsset) external view returns (uint256 balance){
        require(_bAsset != address(0), "bAsset address must be valid");
        (bool exist, uint8 index) = _isAssetInBasket(_bAsset);
        require(exist, "bAsset not exist");

        balance = IERC20(_bAsset).balanceOf(address(this));

        address[] memory _bAssets = new address[](1);
        _bAssets[0] = _bAsset;
        uint256[] memory bAssetBalances = honestSavingsInterface.investmentOf(_bAssets);
        if (bAssetBalances.length > 0) {
            balance = balance.add(bAssetBalances[0]);
        }
    }

    /** @dev Basket balance value of each bAsset */
    function getBasketBalance(address[] calldata _bAssets)
    external view
    returns (uint256 sumBalance, uint256[] memory balances){
        require(_bAssets.length > 0, "bAsset address must be valid");

        sumBalance = 0;
        uint256[] memory bAssetBalances = honestSavingsInterface.investmentOf(_bAssets);
        for (uint256 i = 0; i < _bAssets.length; i++) {
            (bool exist, uint8 index) = _isAssetInBasket(_bAssets[i]);

            if (exist) {
                uint256 poolBalance = IERC20(_bAssets[i]).balanceOf(address(this));
                bAssetBalances[i] = bAssetBalances[i].add(poolBalance);
                sumBalance = sumBalance.add(bAssetBalances[i]);
            }
        }
        balances = bAssetBalances;
    }

    function getBasketAllBalance() external view returns (uint256 sumBalance, address[] memory allBAssets, uint256[] memory balances){
        allBAssets = bAssets;
        sumBalance = 0;
        uint256[] memory bAssetBalances = honestSavingsInterface.investmentOf(bAssets);
        for (uint256 i = 0; i < bAssets.length; i++) {
            (bool exist, uint8 index) = _isAssetInBasket(bAssets[i]);

            if (exist) {
                uint256 poolBalance = IERC20(bAssets[i]).balanceOf(address(this));
                bAssetBalances[i] = bAssetBalances[i].add(poolBalance);
                sumBalance = sumBalance.add(bAssetBalances[i]);
            }
        }
        balances = bAssetBalances;
    }

    /** @dev Basket all bAsset info */
    function getBasket()
    external view
    returns (address[] memory allBAssets, uint8[] memory statuses){
        allBAssets = bAssets;
        statuses = new uint8[](bAssets.length);
        for (uint256 i = 0; i < bAssets.length; i++) {
            statuses[i] = bAssetStatusMap[bAssets[i]];
        }
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

    /** @dev Setters for Gov to update Basket composition */
    function addBAsset(address _bAsset, uint8 _status)
    external
    onlyGovernor
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

        //        bAssets[numberOfBassetsInBasket] = _bAsset;
        bAssets.push(_bAsset);
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
    managerOrGovernor
    returns (uint8 index)
    {
        (bool exists, uint256 i) = _isAssetInBasket(_bAsset);
        require(exists, "bAsset must exist");

        if (_newStatus != bAssetStatusMap[_bAsset]) {
            bAssetStatusMap[_bAsset] = _newStatus;
            emit BassetStatusChanged(_bAsset, _newStatus);
        }
    }

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
            ERC20Detailed(_expectAssets[i]).standardTransfer(_integration, amounts[i]);
        }
        return amounts;
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
}
