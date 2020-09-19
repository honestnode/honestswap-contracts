pragma solidity ^0.5.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {ERC20Detailed} from '@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {IHonestBasket} from '../interfaces/IHonestBasket.sol';
import {StandardERC20} from "../util/StandardERC20.sol";

contract MockHonestBasket is IHonestBasket {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using StandardERC20 for ERC20Detailed;

    address private _hAsset;
    address[] private _bAssets;
    uint8[] private _statues;
    uint256[] private _balances;
    mapping(address => uint8) private bAssetsMap;
    mapping(address => uint8) private bAssetStatusMap;


    function initialize(address _hAssetContract) external {
        _hAsset = _hAssetContract;
    }

    /** @dev Balance value of the bAsset */
    function getBalance(address _bAsset) external view returns (uint256 balance) {
        balance = ERC20Detailed(_bAsset).standardBalanceOf(address(this));
    }

    /** @dev Balance of each bAsset */
    function getBAssetsBalance(address[] calldata _bAssetsIn) external view returns (uint256 sumBalance, uint256[] memory balances) {
        //        return (0, new uint256[](_bAssets.length));
        sumBalance = 0;
        for (uint256 i = 0; i < _bAssetsIn.length; i++) {
            balances[i] = balances[i].add(ERC20Detailed(_bAssetsIn[i]).standardBalanceOf(address(this)));
            sumBalance = sumBalance.add(balances[i]);
        }
    }

    /** @dev Balance of all the bAssets in basket */
    function getBasketAllBalance() external view returns (uint256 sumBalance, address[] memory allBAssets, uint256[] memory balances) {
        sumBalance = 0;
        allBAssets = _bAssets;
        for (uint256 i = 0; i < _bAssets.length; i++) {
            balances[i] = balances[i].add(ERC20Detailed(_bAssets[i]).standardBalanceOf(address(this)));
            sumBalance = sumBalance.add(balances[i]);
        }
        return (sumBalance, _bAssets, _balances);
    }

    /** @dev Basket all bAsset info */
    function getBasket() external view returns (address[] memory bAssets, uint8[] memory statuses) {
        return (_bAssets, _statues);
    }

    /** @dev query bAsset info */
    function getBAssetStatus(address _bAsset) external returns (bool, uint8) {
        return (true, 0);
    }

    /** @dev query bAssets info */
    function getBAssetsStatus(address[] calldata _bAssets) external returns (bool, uint8[] memory) {
        return (true, _statues);
    }

    /** @dev Setters for Gov to update Basket composition */
    function addBAsset(address _bAsset, uint8 _status) external returns (uint8 index) {
        uint8 numberOfBassetsInBasket = uint8(_bAssets.length);
        _bAssets.push(_bAsset);
        _statues.push(_status);
        bAssetStatusMap[_bAsset] = _status;
        bAssetsMap[_bAsset] = numberOfBassetsInBasket;
        return numberOfBassetsInBasket;
    }

    function updateBAssetStatus(address _bAsset, uint8 _newStatus) external returns (uint8 index) {
        return 0;
    }

    function swap(address _input, address _output, uint256 _quantity, address _recipient)
    external returns (uint256 outputQuantity) {
        return 0;
    }

    function getSwapOutput(address _input, address _output, uint256 _quantity)
    external returns (bool, string memory, uint256 outputQuantity) {
        return (false, '', 0);
    }

    function swapBAssets(address _integration, uint256 _totalAmount, address[] calldata _expectAssets)
    external returns (uint256[] memory) {
        require(_integration != address(0), "integration address must be valid");
        require(_totalAmount > 0, "amount must greater than 0");
        uint256 length = _expectAssets.length;
        require(length > 0, "assets length must greater than 0");

        uint256[] memory percentages = new uint256[](length);
        for (uint256 i = 0; i < length; ++i) {
            percentages[i] = uint256(100).div(length).mul(uint256(10) ** uint256(16));
        }

        uint256[] memory amounts = new uint256[](length);
        for (uint256 i = 0; i < length; ++i) {
            amounts[i] = _totalAmount.mul(percentages[i]).div(uint256(1e18));
            ERC20Detailed(_expectAssets[i]).standardTransfer(msg.sender, amounts[i]);
        }
        return amounts;
    }

    function distributeHAssets(address _account, address[] calldata _assets, uint256[] calldata _amounts, uint256 _interests)
    external {
        uint256 totalAmount;
        for (uint256 i = 0; i < _assets.length; ++i) {
            IERC20(_assets[i]).safeTransferFrom(msg.sender, address(this), _amounts[i]);
            totalAmount = totalAmount.add(ERC20Detailed(_assets[i]).standardize(_amounts[i]));
        }
        IERC20(_hAsset).safeTransfer(_account, totalAmount);
    }
}
