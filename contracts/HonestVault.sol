// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;

import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import {IHonestAsset} from "./interfaces/IHonestAsset.sol";
import {IHonestConfiguration} from "./interfaces/IHonestConfiguration.sol";
import {IInvestmentIntegration} from './integrations/IInvestmentIntegration.sol';
import {IHonestFee} from './interfaces/IHonestFee.sol';
import {IHonestVault} from "./interfaces/IHonestVault.sol";
import {AbstractHonestContract} from "./AbstractHonestContract.sol";
import {StandardERC20} from "./libs/StandardERC20.sol";

contract HonestVault is IHonestVault, AbstractHonestContract {

    enum Repository {ALL, VAULT, SAVINGS}

    using SafeERC20 for IERC20;
    using SafeMath for uint;
    using StandardERC20 for ERC20;

    address private _honestConfiguration;
    address private _investmentIntegration;
    address private _honestFee;

    mapping(address => uint) private _weights;
    mapping(address => uint) private _shares;
    uint private _totalWeight;
    uint private _totalShare;

    function initialize(address owner, address honestConfiguration_, address investmentIntegration_, address honestFee_) external initializer() {
        require(owner != address(0), 'HonestVault.initialize: owner address must be valid');
        require(honestConfiguration_ != address(0), 'HonestVault.initialize: honestConfiguration must be valid');
        require(investmentIntegration_ != address(0), 'HonestVault.initialize: investmentIntegration must be valid');
        require(honestFee_ != address(0), 'HonestVault.initialize: honestFee must be valid');

        super.initialize(owner);
        _honestConfiguration = honestConfiguration_;
        _investmentIntegration = investmentIntegration_;
        _honestFee = honestFee_;
    }

    function honestConfiguration() external override view returns (address) {
        return _honestConfiguration;
    }

    function investmentIntegration() external override view returns (address) {
        return _investmentIntegration;
    }

    function honestFee() external override view returns (address) {
        return _honestFee;
    }

    function deposit(address account, uint amount) external override onlyAssetManager returns (uint) {
        require(account != address(0), 'HonestVault.deposit: account must be valid');
        require(amount > 0, 'HonestVault.deposit: amount must be greater than 0');

        uint share = _invest(amount);

        _weights[account] = _weights[account].add(amount);
        _totalWeight = _totalWeight.add(amount);

        _shares[account] = _shares[account].add(share);
        _totalShare = _totalShare.add(share);

        return amount;
    }

    function _invest(uint amount) internal returns (uint) {
        (address[] memory assets, uint[] memory amounts, uint totalAmount) = _balances(Repository.VAULT);

        uint share = amount.mul(uint(1e18)).div(shareValue());

        for (uint i; i < assets.length; ++i) {
            uint investment = ERC20(assets[i]).resume(amount.mul(amounts[i]).div(totalAmount));
            if (investment > 0) {
                IERC20(assets[i]).safeApprove(_investmentIntegration, investment);
                IInvestmentIntegration(_investmentIntegration).invest(address(this), assets[i], investment);
            }
        }
        return share;
    }

    function withdraw(address account, uint weight) external override onlyAssetManager returns (uint) {
        require(account != address(0), 'HonestVault.withdraw: account must be valid');
        require(weight <= _weights[account], 'HonestVault.withdraw: insufficient weight');

        uint share = weight.mul(_shares[account]).div(_weights[account]);
        uint amount = _collect(account, share);

        _weights[account] = _weights[account].sub(weight);
        _totalWeight = _totalWeight.sub(weight);

        _shares[account] = _shares[account].sub(share);
        _totalShare = _totalShare.sub(share);

        return amount;
    }

    function _collect(address account, uint share) internal returns (uint) {

        uint value = shareValue();
        uint collectAmount = share.mul(value).div(uint(1e18));
        uint feeAmount = IHonestFee(_honestFee).claimableRewards();

        (address[] memory assets, uint[] memory shares, uint totalShare, uint price) = IInvestmentIntegration(_investmentIntegration).shares();

        if (feeAmount > 0) {
            IHonestFee(_honestFee).distributeHonestAssetRewards(account, shareValue());
        }
        uint actualShare = collectAmount.sub(feeAmount).mul(uint(1e18)).div(price);

        uint totalAmount;
        for (uint i; i < assets.length; ++i) {
            uint investmentShare = actualShare.mul(shares[i]).div(totalShare);
            uint amount;
            if (investmentShare > shares[i]) {
                amount = IInvestmentIntegration(_investmentIntegration).collect(address(this), assets[i], shares[i]);
            } else {
                amount = IInvestmentIntegration(_investmentIntegration).collect(address(this), assets[i], investmentShare);
            }
            totalAmount = totalAmount.add(amount);
        }
        return totalAmount;
    }

    function balances() external override view returns (address[] memory, uint[] memory, uint) {
        return _balances(Repository.ALL);
    }

    function _balances(Repository repository) internal view returns (address[] memory, uint[] memory, uint) {
        address[] memory assets = IHonestConfiguration(_honestConfiguration).activeBasketAssets();
        uint[] memory amounts = new uint[](assets.length);
        uint totalAmount;
        for (uint i; i < assets.length; ++i) {
            amounts[i] = _balanceOf(repository, assets[i]);
            totalAmount = totalAmount.add(amounts[i]);
        }
        return (assets, amounts, totalAmount);
    }

    function _balanceOf(Repository repository, address asset) internal view returns (uint) {
        if (repository == Repository.VAULT) {
            return ERC20(asset).standardBalanceOf(address(this));
        } else if (repository == Repository.SAVINGS) {
            return _investmentOf(asset).add(IHonestFee(_honestFee).totalFee());
        } else {
            return ERC20(asset).standardBalanceOf(address(this)).add(_investmentOf(asset));
        }
    }

    function _investmentOf(address asset) internal view returns (uint) {
        return IInvestmentIntegration(_investmentIntegration).balanceOf(asset);
    }

    function weightOf(address account) external override view returns (uint) {
        return _weights[account];
    }

    function shareOf(address account) external override view returns (uint) {
        return _shares[account];
    }

    function shareValue() public override view returns (uint) {
        if (_totalShare == 0) {
            return uint(1e18);
        }
        uint fee = IHonestFee(_honestFee).claimableRewards();
        (, , uint totalBalance) = _balances(Repository.SAVINGS);
        return totalBalance.add(fee).mul(uint(1e18)).div(_totalShare);
    }

    function distributeProportionally(address account, uint amount) external override onlyAssetManager {
        (address[] memory assets, uint[] memory amounts, uint totalAmount) = _balances(Repository.VAULT);
        for (uint i; i < assets.length; ++i) {
            if (amounts[i] > 0) {
                uint assetAmount = amounts[i].mul(amount).div(totalAmount);
                if (assetAmount < amounts[i]) {
                    amounts[i] = assetAmount;
                }
                _distributeVault(account, assets[i], amounts[i]);
            }
        }
    }

    function distributeManually(address account, address[] calldata assets, uint[] calldata amounts) external override onlyAssetManager {
        uint[] memory gapAmounts = new uint[](assets.length);
        uint gaps;
        for (uint i; i < assets.length; ++i) {
            require(amounts[i] > 0, 'amount must be greater than 0');
            require(amounts[i] <= _balanceOf(Repository.ALL, assets[i]), 'insufficient balance');
            uint vaultAmount = _balanceOf(Repository.VAULT, assets[i]);
            if (amounts[i] > vaultAmount) {
                _distributeVault(account, assets[i], vaultAmount);
                gapAmounts[i] = amounts[i].sub(vaultAmount);
                gaps += gapAmounts[i];
            } else {
                _distributeVault(account, assets[i], amounts[i]);
            }
        }
        if (gaps > 0) {
            _distributeSavings(account, assets, gapAmounts, gaps);
        }
    }

    function _distributeVault(address to, address asset, uint amount) internal {
        ERC20(asset).standardTransfer(to, amount);
    }

    function _distributeSavings(address account, address[] memory assets, uint[] memory borrows, uint total) internal {
        for (uint i; i < assets.length; ++i) {
            uint price = IInvestmentIntegration(_investmentIntegration).priceOf(assets[i]);
            uint share = borrows[i].mul(uint(1e18)).div(price);
            IInvestmentIntegration(_investmentIntegration).collect(account, assets[i], share);
        }
        _invest(total);
    }

    function setHonestConfiguration(address honestConfiguration_) external override onlyGovernor {
        require(honestConfiguration_ != address(0), 'HonestVault.setHonestConfiguration: honestConfiguration must be valid');

        _honestConfiguration = honestConfiguration_;
    }

    function setInvestmentIntegration(address investmentIntegration_) external override onlyGovernor {
        require(investmentIntegration_ != address(0), 'HonestVault.setInvestmentIntegration: investmentIntegration must be valid');

        _investmentIntegration = investmentIntegration_;
    }

    function setHonestFee(address honestFee_) external override onlyGovernor {
        require(honestFee_ != address(0), 'HonestVault.setHonestFee: honestFee must be valid');

        _honestFee = honestFee_;
    }
}