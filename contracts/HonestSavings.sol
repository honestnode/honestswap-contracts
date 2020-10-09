// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;
//
//import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
//import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
//import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
//import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
//
//import {IHonestBonus} from "./interfaces/IHonestBonus.sol";
//import {IHonestFee} from './interfaces/IHonestFee.sol';
//import {IHonestSavings} from "./interfaces/IHonestSavings.sol";
//import {IInvestmentIntegration} from "./integrations/IInvestmentIntegration.sol";
//import {StandardERC20} from "./libs/StandardERC20.sol";
//import {AbstractHonestContract} from "./AbstractHonestContract.sol";
//
//contract HonestSavings is IHonestSavings, AbstractHonestContract {
//
//    using SafeERC20 for IERC20;
//    using SafeMath for uint;
//    using StandardERC20 for ERC20;
//
//    event SavingsDeposited(address indexed account, uint weight, uint share);
//    event SavingsRedeemed(address indexed account, uint weight, uint share);
//
//    address private _honestConfiguration;
//    address private _investmentIntegration;
//
//    mapping(address => uint) private _weights;
//    mapping(address => uint) private _shares;
//
//    uint private _totalWeight;
//    uint private _totalShare;
//
//    uint private _previousApyUpdateTime;
//    uint private _previousTotalValue;
//    int256 private _apy;
//
//    function initialize(address honestConfiguration, address investmentIntegration)
//    external initializer() {
//        require(honestConfiguration != address(0), 'HonestSavings.initialize: honestConfiguration must be valid');
//        require(investmentIntegration != address(0), 'HonestSavings.initialize: investmentIntegration must be valid');
//
//        _honestConfiguration = honestConfiguration;
//        _investmentIntegration = investmentIntegration;
//        _previousApyUpdateTime = block.timestamp;
//    }
//
//    function honestConfiguration() external override view returns (address) {
//        return _honestConfiguration;
//    }
//
//    function investmentIntegration() external override view returns (address) {
//        return _investmentIntegration;
//    }
//
//    function weightOf(address account) external override view returns (uint) {
//        return _weights[account];
//    }
//
//    function totalWeight() external override view returns (uint) {
//        return _totalWeight;
//    }
//
//    function shareOf(address account) external override view returns (uint) {
//        return _shares[account];
//    }
//
//    function totalShare() public override view returns (uint) {
//        return _totalShare;
//    }
//
//    function totalValue() public override view returns (uint) {
//        return IInvestmentIntegration(_investmentIntegration).totalBalance();
//    }
//
//    function sharePrice() public override view returns (uint) {
//        if (totalShare() == 0) {
//            return 1;
//        }
//        return totalValue().div(totalShare());
//    }
//
//    function deposit(address account, address vault, address[] calldata assets, uint[] calldata amounts)
//    external override onlyAssetManager {
//        require(account != address(0), 'HonestSavings.deposit: account must be valid');
//        require(vault != address(0), 'HonestSavings.deposit: vault must be valid');
//        require(assets.length > 0, 'HonestSavings.deposit: assets length must be greater than 0');
//        require(assets.length == amounts.length, 'HonestSavings.deposit: mismatch assets length and amounts length');
//
//        uint totalWeight;
//        uint totalShare;
//
//        for (uint i; i < assets.length; ++i) {
//            uint amount = ERC20(assets[i]).resume(amounts[i]);
//            IERC20(assets[i]).transferFrom(vault, address(this), amount);
//            totalWeight = totalWeight.add(amounts[i]);
//            totalShare = _invest(vault, assets[i], amount);
//        }
//
//        _weights[account] = _weights[account].add(totalWeight);
//        _totalWeight = _totalWeight.add(totalWeight);
//
//        _shares[account] = _shares[account].add(totalShare);
//        _totalShare = _totalShare.add(totalShare);
//
//        _updateApy();
//
//        emit SavingsDeposited(account, totalWeight, totalShare);
//    }
//
//    function _invest(address account, address asset, uint amount) internal returns (uint) {
//        if (amount == 0) {
//            return 0;
//        }
//        return IInvestmentIntegration(_investmentIntegration).invest(account, asset, amount);
//    }
//
//    function withdraw(address account, address vault, uint weight) external override onlyAssetManager {
//        require(account != address(0), 'HonestSavings.withdraw: account must be valid');
//        require(vault != address(0), 'HonestSavings.deposit: vault must be valid');
//        require(weight > 0, 'HonestSavings.withdraw: weight must be greater than 0');
//
//        uint share = weight.mul(_shares[account]).div(_weights[account]);
//
//        _collect(vault, weight);
//
//        _weights[account] = _weights[account].sub(weight);
//        _totalWeight = _totalWeight.sub(weight);
//
//        _shares[account] = _shares[account].sub(share);
//        _totalShare = _totalShare.sub(share);
//
//        _updateApy();
//
//        emit SavingsRedeemed(account, weight, share);
//    }
//
//    function _collect(address account, uint share) internal {
//        (address[] memory assets, uint[] memory shares, uint totalShare, uint price) =
//        IInvestmentIntegration(_investmentIntegration).shares();
//        require(share < totalShare, 'HonestSavings._collect: insufficient balance');
//
//        for (uint i; i < assets.length; ++i) {
//            IInvestmentIntegration(_investmentIntegration).collect(account, assets[i], share.mul(shares[i]).div(totalShare));
//        }
//    }
//
//    function _updateApy() internal {
//        //        if (block.timestamp < _previousApyUpdateTime.add(24 hours)) {
//        //            return;
//        //        }
//        //        uint currentValue = IInvestmentIntegration(_investmentIntegration).totalBalance().add(IHonestFee(_fee).totalFee());
//        //        if (currentValue < _totalSavings) {
//        //            return;
//        //        }
//        //        currentValue = currentValue - _totalSavings;
//        //        if (currentValue == 0) {
//        //            return;
//        //        }
//        //        if (currentValue >= _previousTotalValue) {
//        //            _apy = int256(currentValue.sub(_previousTotalValue).mul(365 days).div(block.timestamp.sub(_previousApyUpdateTime)));
//        //        } else {
//        //            _apy = int256(- (_previousTotalValue.sub(currentValue).mul(365 days).div(block.timestamp.sub(_previousApyUpdateTime))));
//        //        }
//        //        _previousTotalValue = currentValue;
//        //        _previousApyUpdateTime = block.timestamp;
//    }
//
//    function apy() external override view returns (int256) {
//        return _apy;
//    }
//
//    function swap(address account, address[] calldata bAssets, uint[] calldata borrows, address[] calldata sAssets, uint[] calldata supplies)
//    external override onlyAssetManager {
//        require(bAssets.length == borrows.length, "HonestSavings.swap: mismatch borrows amounts length");
//        require(sAssets.length == supplies.length, "HonestSavings.swap: mismatch supplies amounts length");
//
//        uint supply = _takeSwapSupplies(sAssets, supplies);
//        uint borrow = _giveSwapBorrows(account, bAssets, borrows);
//
//        require(supply > 0, 'HonestSavings.swap: unexpect supply value');
//        require(borrow > 0, 'HonestSavings.swap: unexpect borrow value');
//        require(borrow <= supply, 'HonestSavings.swap: insufficient supplies');
//    }
//
//    function _takeSwapSupplies(address[] memory sAssets, uint[] memory supplies) internal returns (uint) {
//        uint supply;
//        for (uint i = 0; i < sAssets.length; ++i) {
//            if (supplies[i] == 0) {
//                continue;
//            }
//            uint amount = ERC20(sAssets[i]).resume(supplies[i]);
//            IERC20(sAssets[i]).safeTransferFrom(_msgSender(), address(this), amount);
//            IERC20(sAssets[i]).safeApprove(_investmentIntegration, amount);
//            IInvestmentIntegration(_investmentIntegration).invest(address(this), sAssets[i], amount);
//            supply = supply.add(supplies[i]);
//        }
//        return supply;
//    }
//
//    function _giveSwapBorrows(address account, address[] memory assets, uint[] memory borrows) internal returns (uint) {
//        uint borrow;
//        for (uint i = 0; i < assets.length; ++i) {
//            if (borrows[i] == 0) {
//                continue;
//            }
//            uint share = borrows[i].mul(uint(1e18)).div(IInvestmentIntegration(_investmentIntegration).priceOf(assets[i]));
//            IInvestmentIntegration(_investmentIntegration).collect(account, assets[i], share);
//            borrow = borrow.add(borrows[i]);
//        }
//        return borrow;
//    }
//
//    function setHonestConfiguration(address honestConfiguration_) external override onlyGovernor {
//        require(honestConfiguration_ != address(0), 'HonestSavings.setHonestConfiguration: honestConfiguration must be valid');
//
//        _honestConfiguration = honestConfiguration_;
//    }
//
//    function setInvestmentIntegration(address investmentIntegration_) external override onlyGovernor {
//        require(investmentIntegration_ != address(0), 'HonestSavings.setInvestmentIntegration: investmentIntegration must be valid');
//
//        _investmentIntegration = investmentIntegration_;
//    }
//}