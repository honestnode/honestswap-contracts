// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;

import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import {StandardERC20} from "./libs/StandardERC20.sol";
import {IHonestAssetManager} from "./interfaces/IHonestAssetManager.sol";
import {AbstractHonestContract} from "./AbstractHonestContract.sol";
import {IHonestConfiguration} from './interfaces/IHonestConfiguration.sol';
import {IHonestVault} from './interfaces/IHonestVault.sol';
import {IHonestAsset} from './interfaces/IHonestAsset.sol';

contract HonestAssetManager is IHonestAssetManager, AbstractHonestContract {

    address private _honestConfiguration;
    address private _honestVault;

    using SafeERC20 for IERC20;
    using SafeMath for uint;
    using StandardERC20 for ERC20;

    function initialize(address owner, address honestConfiguration_, address honestVault_) external initializer() {
        require(owner != address(0), 'HonestAssetManager.initialize: owner address must be valid');
        require(honestConfiguration_ != address(0), 'HonestAssetManager.initialize: honestConfiguration must be valid');
        require(honestVault_ != address(0), 'HonestAssetManager.initialize: honestVault must be valid');

        super.initialize(owner);
        _honestConfiguration = honestConfiguration_;
        _honestVault = honestVault_;
    }

    function honestConfiguration() external override view returns (address) {
        return _honestConfiguration;
    }

    function honestVault() external override view returns (address) {
        return _honestVault;
    }

    function _honestAsset() internal view returns (address) {
        return IHonestConfiguration(_honestConfiguration).honestAsset();
    }

    function mint(address[] calldata bAssets, uint[] calldata amounts) external override {
        require(bAssets.length > 0, 'HonestAssetManager.mint: assets length must be greater than 0');
        require(bAssets.length == amounts.length, 'HonestAssetManager.mint: assets length must be equal with amounts length');

        uint totalAmount;
        for(uint i; i < bAssets.length; ++i) {
            IERC20(bAssets[i]).safeTransferFrom(_msgSender(), _honestVault, amounts[i]);
            uint amount = ERC20(bAssets[i]).standardize(amounts[i]);
            totalAmount = totalAmount.add(amount);
        }

        IHonestAsset(_honestAsset()).mint(_msgSender(), totalAmount);
    }

    function redeemProportionally(uint amount) external override {
        require(amount > 0, 'HonestAssetManager.redeemProportionally: amount must be greater than 0');

        IHonestAsset(_honestAsset()).burn(_msgSender(), amount);

        IHonestVault(_honestVault).distributeProportionally(_msgSender(), amount);
    }

    function redeemManually(address[] calldata assets, uint[] calldata amounts) external override {
        uint totalAmount;
        for(uint i; i < assets.length; ++i) {
            require(amounts[i] > 0, 'HonestAssetManager.redeemManually: amount must be greater than 0');
            totalAmount = totalAmount.add(amounts[i]);
        }
        uint feeRate = IHonestConfiguration(_honestConfiguration).redeemFeeRate();
        uint fee = totalAmount.mul(feeRate).div(uint(1e18));

        IERC20(_honestAsset()).safeTransferFrom(_msgSender(), IHonestVault(_honestVault).honestFee(), fee);
        IHonestAsset(_honestAsset()).burn(_msgSender(), totalAmount);

        IHonestVault(_honestVault).distributeManually(_msgSender(), assets, amounts);
    }

    function swap(address from, address to, uint amount) external override {
        require(amount > 0, 'HonestAssetManager.swap: amount must be greater than 0');

        uint swapFeeRate = IHonestConfiguration(_honestConfiguration).swapFeeRate();
        uint standardAmount = ERC20(from).standardize(amount);
        uint fee = standardAmount.mul(swapFeeRate).div(uint(1e18));

        ERC20(from).standardTransferFrom(_msgSender(), _honestVault, standardAmount.add(fee));

        IHonestAsset(_honestAsset()).mint(IHonestVault(_honestVault).honestFee(), fee);

        address[] memory assets = new address[](1);
        assets[0] = to;
        uint[] memory amounts = new uint[](1);
        amounts[0] = standardAmount;
        IHonestVault(_honestVault).distributeManually(_msgSender(), assets, amounts);
    }

    function deposit(uint amount) external override {
        require(amount > 0, 'HonestAssetManager.deposit: amount must be greater than 0');

        IERC20(_honestAsset()).safeTransferFrom(_msgSender(), address(this), amount);
        IHonestVault(_honestVault).deposit(_msgSender(), amount);
    }

    function withdraw(uint weight) external override {
        require(weight > 0, 'HonestAssetManager.withdraw: amount must be greater than 0');

        uint amount = IHonestVault(_honestVault).withdraw(_msgSender(), weight);
        if (amount > weight) {
            IHonestAsset(_honestAsset()).mint(address(this), amount.sub(weight));
        }
        IHonestAsset(_honestAsset()).transfer(_msgSender(), amount);
    }

    function _mintFee(uint fee) internal {

    }

    function setHonestConfiguration(address honestConfiguration_) external override {
        require(honestConfiguration_ != address(0), 'HonestAssetManager.setHonestConfiguration: honestConfiguration must be valid');

        _honestConfiguration = honestConfiguration_;
    }

    function setHonestVault(address honestVault_) external override {
        require(honestVault_ != address(0), 'HonestAssetManager.initialize: honestVault must be valid');

        _honestVault = honestVault_;
    }
}