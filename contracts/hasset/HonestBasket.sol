pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Initializable} from "@openzeppelin/upgrades/contracts/Initializable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {InitializablePausableModule} from "../common/InitializablePausableModule.sol";
import {InitializableReentrancyGuard} from "../common/InitializableReentrancyGuard.sol";
import {IHonestBasket} from "../interfaces/IHonestBasket.sol";
import {IHonestSavings} from "../interfaces/IHonestSavings.sol";
import {IPlatformIntegration} from "../interfaces/IPlatformIntegration.sol";

contract HonestBasket is
Initializable,
IHonestBasket,
InitializablePausableModule,
InitializableReentrancyGuard {

    using SafeMath for uint256;

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

        honestSavingsInterface = IHonestSaving(_honestSavingsInterface);

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

    /** @dev Basket balance value of each bAsset */
    function getBasketBalance(address[] calldata _bAssets)
    external view
    returns (uint256[] memory){
        require(_bAssets.length > 0, "bAsset address must be valid");

        uint256[] memory bAssetBalances = honestSavingsInterface.investmentOf(_bAssets);
        for (uint256 i = 0; i < _bAssets.length; i++) {
            (bool exist, uint8 index) = _isAssetInBasket(_bAssets[i]);

            if (exist) {
                uint256 poolBalance = IERC20(_bAssets[i]).balanceOf(address(this));
                bAssetBalances[i] = bAssetBalances[i].add(poolBalance);
            }
        }
        return bAssetBalances;
    }

    /** @dev Basket all bAsset info */
    function getBasket()
    external view
    returns (address[] memory allBAssets, uint8[] memory statuses){
        allBAssets = bAssets;
        statuses = uint8[bAssets.length];
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
        uint8[] statuses = uint8[_bAssets.length];
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
            bAssetStatuses[_bAsset] = _newStatus;
            index = i;
            emit BassetStatusChanged(_bAsset, _newStatus);
        }
    }

}
