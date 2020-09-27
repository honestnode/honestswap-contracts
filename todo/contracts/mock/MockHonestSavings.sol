pragma solidity ^0.6.0;

import {IHonestSavings} from "../interfaces/IHonestSavings.sol";
import {SafeMath} from '@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol';
import {IERC20} from '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol';
import {ERC20} from '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol';
import {StandardERC20} from "../utils/StandardERC20.sol";

contract MockHonestSavings is IHonestSavings {

    using SafeERC20 for IERC20;
    using SafeMath for uint;
    using StandardERC20 for ERC20;

    address[] private _assets;
    mapping(address => uint) _amounts;
    uint private _totalAmount;

    function mock(address asset, uint amount) external {
        _assets.push(asset);
        _amounts[asset] = _amounts[asset].add(amount);
        _totalAmount = _totalAmount.add(amount);
    }

    function initialize(address _hAssetContract, address _basketContract, address _investmentContract, address _feeContract, address _bonusContract)
    external {}

    function deposit(uint _amount) external returns (uint) {
        return 0;
    }

    function withdraw(uint _shares) external returns (uint) {
        return 0;
    }

    function savingsOf(address _account) external view returns (uint) {
        return 0;
    }

    function sharesOf(address _account) external view returns (uint) {
        return 0;
    }

    function totalSavings() external view returns (uint) {
        return 0;
    }

    function totalShares() external view returns (uint) {
        return 0;
    }

    function sharePrice() external view returns (uint) {
        return 0;
    }

    function totalValue() external view returns (uint) {
        return 0;
    }

    function updateApy() external {}

    function apy() external view returns (int256) {
        return 0;
    }

    function swap(address _account, address[] calldata _bAssets, uint[] calldata _borrows, address[] calldata _sAssets, uint[] calldata _supplies) external {
        require(_bAssets.length == _borrows.length, "mismatch borrows amounts length");
        require(_sAssets.length == _supplies.length, "mismatch supplies amounts length");

        uint supplies = _takeSwapSupplies(_sAssets, _supplies);
        uint borrows = _giveSwapBorrows(_account, _bAssets, _borrows);

        require(borrows > 0, "amounts must greater than 0");
        require(borrows == supplies, "mismatch amounts");
    }

    function _takeSwapSupplies(address[] memory _sAssets, uint[] memory _supplies) internal returns (uint) {
        uint supplies;
        for (uint i = 0; i < _sAssets.length; ++i) {
            if (_supplies[i] == 0) {
                continue;
            }
            uint amount = ERC20(_sAssets[i]).resume(_supplies[i]);
            IERC20(_sAssets[i]).safeTransferFrom(msg.sender, address(this), amount);
            supplies = supplies.add(_supplies[i]);
        }
        return supplies;
    }

    function _giveSwapBorrows(address _account, address[] memory _bAssets, uint[] memory _borrows) internal returns (uint) {
        uint borrows;
        for (uint i = 0; i < _bAssets.length; ++i) {
            if (_borrows[i] == 0) {
                continue;
            }
            uint amount = ERC20(_bAssets[i]).resume(_borrows[i]);
            IERC20(_bAssets[i]).safeTransfer(_account, amount);
            borrows = borrows.add(_borrows[i]);
        }
        return borrows;
    }

    function investments() external view returns (address[] memory, uint[] memory, uint) {
        uint[] memory amounts = new uint[](_assets.length);
        for(uint i = 0; i < _assets.length; ++i) {
            amounts[i] = _amounts[_assets[i]];
        }
        return (_assets, amounts, _totalAmount);
    }

    function investmentOf(address bAsset) external view returns (uint) {
        return _amounts[bAsset];
    }
}