// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;

import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {ReentrancyGuardUpgradeSafe} from '@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol';
import {IInvestmentIntegration} from "./IInvestmentIntegration.sol";
import {StandardERC20} from "../libs/StandardERC20.sol";
import {AbstractHonestContract} from "../AbstractHonestContract.sol";
import {IHonestConfiguration} from '../interfaces/IHonestConfiguration.sol';

interface yTokenV2 {
    function deposit(uint _amount) external;

    function withdraw(uint _shares) external;

    function getPricePerFullShare() external view returns (uint);
}

contract YearnV2Integration is IInvestmentIntegration, AbstractHonestContract, ReentrancyGuardUpgradeSafe {

    using SafeERC20 for IERC20;
    using SafeMath for uint;
    using StandardERC20 for ERC20;

    address private _honestConfiguration;

    function initialize(address owner, address honestConfiguration) external initializer() {
        require(owner != address(0), 'YearnV2Integration.initialize: owner address must be valid');
        require(honestConfiguration != address(0), 'YearnV2Integration.initialize: honestConfiguration address must be valid');

        super.initialize(owner);
        __ReentrancyGuard_init();
        _honestConfiguration = honestConfiguration;
    }

    function invest(address account, address asset, uint amount) external override onlyVault nonReentrant returns (uint) {
        require(account != address(0), "YearnV2Integration.invest: account must be valid");
        require(amount > 0, "YearnV2Integration.invest: invest must be greater than 0");

        IERC20(asset).safeTransferFrom(account, address(this), amount);

        address yToken = _contractOf(asset);
        uint before = IERC20(yToken).balanceOf(address(this));
        IERC20(asset).safeApprove(yToken, amount);
        yTokenV2(yToken).deposit(amount);

        uint credits = IERC20(yToken).balanceOf(address(this)).sub(before);
        return ERC20(yToken).standardize(credits);
    }

    function collect(address account, address asset, uint credits) external override onlyVault nonReentrant returns (uint) {
        require(account != address(0), "YearnV2Integration.collect: account must be valid");
        require(credits > 0, "YearnV2Integration.collect: credits must be greater than 0");

        yTokenV2 yToken = yTokenV2(_contractOf(asset));
        uint originShares = ERC20(address(yToken)).resume(credits);
        uint amount = originShares.mul(yToken.getPricePerFullShare()).div(uint(1e18));
        yToken.withdraw(originShares);

        require(amount <= IERC20(asset).balanceOf(address(this)), "YearnV2Integration.collect: insufficient balance");
        IERC20(asset).safeTransfer(account, amount);

        return ERC20(asset).standardize(amount);
    }

    function priceOf(address asset) external override view returns (uint) {
        address yToken = _contractOf(asset);
        return yTokenV2(yToken).getPricePerFullShare();
    }

    function shareOf(address asset) public override view returns (uint) {
        address yToken = _contractOf(asset);
        return ERC20(yToken).standardBalanceOf(address(this));
    }

    function shares() external override view returns (address[] memory, uint[] memory, uint, uint) {
        address[] memory assets = IHonestConfiguration(_honestConfiguration).activeBasketAssets();
        uint[] memory credits = new uint[](assets.length);
        uint totalShare;
        uint totalBalance;
        for (uint i = 0; i < assets.length; ++i) {
            credits[i] = shareOf(assets[i]);
            totalShare = totalShare.add(credits[i]);
            totalBalance = totalBalance.add(_balanceOf(assets[i]));
        }
        return (assets, credits, totalShare, totalBalance.mul(uint(1e18)).div(totalShare));
    }

    function balanceOf(address asset) external override view returns (uint) {
        return _balanceOf(asset);
    }

    function balances() external override view returns (address[] memory, uint[] memory, uint) {
        address[] memory assets = IHonestConfiguration(_honestConfiguration).activeBasketAssets();
        uint[] memory aBalances = new uint[](assets.length);
        uint totalBalances;
        for (uint i = 0; i < assets.length; ++i) {
            aBalances[i] = _balanceOf(assets[i]);
            totalBalances = totalBalances.add(aBalances[i]);
        }
        return (assets, aBalances, totalBalances);
    }

    function totalBalance() external override view returns (uint) {
        address[] memory assets = IHonestConfiguration(_honestConfiguration).activeBasketAssets();
        uint balance;
        for (uint i = 0; i < assets.length; ++i) {
            balance = balance.add(_balanceOf(assets[i]));
        }
        return balance;
    }

    function _contractOf(address asset) internal view returns (address) {
        return IHonestConfiguration(_honestConfiguration).basketAssetInvestmentIntegration(asset);
    }

    function _balanceOf(address _asset) internal view returns (uint) {
        address yToken = _contractOf(_asset);

        uint credits = ERC20(yToken).standardBalanceOf(address(this));
        if (credits == 0) {
            return 0;
        }
        return yTokenV2(yToken).getPricePerFullShare().mul(credits).div(uint(1e18));
    }
}