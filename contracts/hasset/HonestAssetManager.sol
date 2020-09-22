pragma solidity ^0.5.0;

import {WhitelistAdminRole} from '@openzeppelin/contracts/access/roles/WhitelistAdminRole.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ERC20Detailed} from '@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol';
import {ERC20Mintable} from '@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {IHonestAsset} from '../interfaces/IHonestAsset.sol';
import {IHonestAssetManager} from '../interfaces/IHonestAssetManager.sol';
import {IHonestVault} from '../interfaces/IHonestVault.sol';
import {IHonestSavings} from '../interfaces/IHonestSavings.sol';
import {IHonestFee} from '../interfaces/IHonestFee.sol';
import {IHonestBonus} from '../interfaces/IHonestBonus.sol';
import {StandardERC20} from '../util/StandardERC20.sol';

contract HonestAssetManager is IHonestAssetManager, WhitelistAdminRole, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using SafeMath for uint;
    using StandardERC20 for ERC20Detailed;

    event Minted(address indexed minter, address[] bAssets, uint[] inputs, uint output, address recipient);
    event Redeemed(address indexed redeemer, uint input, address[] bAssets, uint[] outputs, address recipient);
    event Swapped(address indexed swapper, address from, address to, uint amount, address recipient);

    event FeeChanged(uint fee);

    address private _assetContract;
    address private _vaultContract;
    address private _feeContract;
    address private _bonusContract;

    function initialize(address assetAddress, address vaultAddress, address feeAddress, address bonusAddress) external onlyWhitelistAdmin {
        setHonestAsset(assetAddress);
        setHonestVault(vaultAddress);
        setHonestFee(feeAddress);
        setHonestBonus(bonusAddress);
    }

    function honestAsset() external view returns (address) {
        return _assetContract;
    }

    function honestVault() external view returns (address) {
        return _vaultContract;
    }

    function honestFee() external view returns (address) {
        return _feeContract;
    }

    function honestBonus() external view returns (address) {
        return _bonusContract;
    }

    function setHonestAsset(address contractAddress) public onlyWhitelistAdmin {
        require(contractAddress != address(0), 'address must be valid');
        _assetContract = contractAddress;
    }

    function setHonestVault(address contractAddress) public onlyWhitelistAdmin {
        require(contractAddress != address(0), 'address must be valid');
        _vaultContract = contractAddress;
    }

    function setHonestFee(address contractAddress) public onlyWhitelistAdmin {
        require(contractAddress != address(0), 'address must be valid');
        _feeContract = contractAddress;
    }

    function setHonestBonus(address contractAddress) public onlyWhitelistAdmin {
        require(contractAddress != address(0), 'address must be valid');
        _bonusContract = contractAddress;
    }

    function mint(address[] calldata bAssets, uint[] calldata amounts) external {
        mintTo(bAssets, amounts, _msgSender());
    }

    function mintTo(address[] memory bAssets, uint[] memory amounts, address recipient) public {
        require(bAssets.length > 0, 'empty inputs');
        require(bAssets.length == amounts.length, 'mismatch inputs length');
        require(recipient != address(0), 'recipient must be valid');
        require(IHonestVault(_vaultContract).isAssetsAllActive(bAssets), 'inactive assets');

        uint total;
        for (uint i = 0; i < bAssets.length; ++i) {
            if (amounts[i] > 0) {
                IERC20(bAssets[i]).safeTransferFrom(_msgSender(), _vaultContract, amounts[i]);
                total = total.add(ERC20Detailed(bAssets[i]).standardize(amounts[i]));
            }
        }

        IHonestAsset(_assetContract).mint(recipient, total);

        uint redeemFeeRate = IHonestFee(_feeContract).redeemFeeRate();
        uint bonus = IHonestBonus(_bonusContract).calculateBonuses(bAssets, amounts, redeemFeeRate);
        if (bonus > 0) {
            IHonestBonus(_bonusContract).addBonus(recipient, bonus);
        }

        emit Minted(_msgSender(), bAssets, amounts, total, recipient);
    }

    function redeemProportionally(uint amount) external {
        redeemProportionallyTo(amount, _msgSender());
    }

    function redeemProportionallyTo(uint amount, address recipient) public {
        require(amount > 0, 'amount must be greater than 0');
        require(recipient != address(0), 'address must be valid');

        IHonestAsset(_assetContract).burn(recipient, amount);

        (address[] memory assets, uint[] memory amounts) = IHonestVault(_vaultContract).distributeProportionally(recipient, amount, IHonestVault.Repository.VAULT);

        emit Redeemed(_msgSender(), amount, assets, amounts, recipient);
    }

    function redeemManually(address[] calldata bAssets, uint[] calldata amounts) external {
        redeemManuallyTo(bAssets, amounts, _msgSender());
    }

    function redeemManuallyTo(address[] memory bAssets, uint[] memory amounts, address recipient) public {
        require(bAssets.length > 0, 'empty inputs');
        require(bAssets.length == amounts.length, 'mismatch inputs length');
        require(recipient != address(0), 'recipient must be valid');
        require(IHonestVault(_vaultContract).isAssetsAllActive(bAssets), 'inactive assets');

        uint total;
        for (uint i = 0; i < bAssets.length; ++i) {
            if (amounts[i] > 0) {
                amounts[i] = ERC20Detailed(bAssets[i]).standardize(amounts[i]);
                total = total.add(amounts[i]);
            }
        }

        IHonestAsset(_assetContract).burn(recipient, total);

        uint feeRate = IHonestFee(_feeContract).redeemFeeRate();
        _chargeFee(total, feeRate);

        IHonestVault(_vaultContract).distributeManually(recipient, bAssets, amounts, IHonestVault.Repository.ALL);

        emit Redeemed(_msgSender(), total, bAssets, amounts, recipient);
    }

    function swap(address from, address to, uint amount) external {
        swapTo(from, to, amount, _msgSender());
    }

    function swapTo(address from, address to, uint amount, address recipient) public {
        require(from != address(0), 'from must be valid');
        require(to != address(0), 'to must be valid');
        require(amount > 0, 'amount must be greater than 0');

        IERC20(from).safeTransferFrom(_msgSender(), _vaultContract, amount);

        uint feeRate = IHonestFee(_feeContract).swapFeeRate();
        uint fee = _chargeFee(ERC20Detailed(from).standardize(amount), feeRate);

        address[] memory assets = new address[](1);
        assets[0] = to;
        uint[] memory amounts = new uint[](1);
        amounts[0] = ERC20Detailed(from).standardize(amount).sub(fee);

        IHonestVault(_vaultContract).distributeManually(recipient, assets, amounts, IHonestVault.Repository.ALL);

        emit Swapped(_msgSender(), from, to, amount, recipient);
    }

    function deposit(address to, uint amount)
    external onlyWhitelistAdmin returns (uint[] memory) {
        require(to != address(0), "to address must be valid");
        require(amount > 0, "amount must be greater than 0");

        IERC20(_assetContract).safeTransferFrom(_msgSender(), address(this), amount);
        (address[] memory assets, uint256[] memory amounts) = IHonestVault(_vaultContract).distributeProportionally(to, amount, IHonestVault.Repository.VAULT);
        return amounts;
    }

    function withdraw(address to, address[] calldata assets, uint[] calldata amounts, uint interests)
    external onlyWhitelistAdmin {
        require(to != address(0), "to address must be valid");
        require(assets.length > 0, "assets must be not empty");

        uint total;
        for(uint i = 0; i < assets.length; ++i) {
            if (amounts[i] > 0) {
                IERC20(assets[i]).safeTransferFrom(_msgSender(), _vaultContract, amounts[i]);
                total = total.add(ERC20Detailed(assets[i]).standardize(amounts[i]));
            }
        }
        require(total >= interests, 'unexpected withdraw values');

        if (interests > 0) {
            IERC20(_assetContract).safeTransfer(to, total.sub(interests));
            IHonestAsset(_assetContract).mint(to, interests);
        } else {
            IERC20(_assetContract).safeTransfer(to, total);
        }
    }

    function _chargeFee(uint amount, uint feeRate) internal returns (uint) {
        uint fee = amount.mul(feeRate).div(uint(1e18));
        IHonestAsset(_assetContract).mint(_feeContract, fee);

        emit FeeChanged(fee);
        return fee;
    }
}