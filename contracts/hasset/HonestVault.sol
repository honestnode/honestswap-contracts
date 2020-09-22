pragma solidity ^0.5.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ERC20Detailed} from '@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {WhitelistAdminRole} from '@openzeppelin/contracts/access/roles/WhitelistAdminRole.sol';
import {EnumerableSet} from '@openzeppelin/contracts/utils/EnumerableSet.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import {IHonestVault} from "../interfaces/IHonestVault.sol";
import {IHonestSavings} from '../interfaces/IHonestSavings.sol';
import {StandardERC20} from "../util/StandardERC20.sol";

contract HonestVault is IHonestVault, WhitelistAdminRole {

    using SafeERC20 for IERC20;
    using SafeMath for uint;
    using StandardERC20 for ERC20Detailed;
    using EnumerableSet for EnumerableSet.AddressSet;

    address private _honestAsset;
    address private _honestSavings;
    EnumerableSet.AddressSet private _assets;
    mapping(address => bool) private _assetStates;

    function initialize(address honestAsset, address honestSavings, address[] calldata bAssets) external onlyWhitelistAdmin {
        setHonestAsset(honestAsset);
        setHonestSavings(honestSavings);
        for (uint i = 0; i < bAssets.length; ++i) {
            addBasketAsset(bAssets[i]);
        }
    }

    function honestAsset() public view returns (address) {
        return _honestAsset;
    }

    function honestSavings() external view returns (address) {
        return _honestSavings;
    }

    function basketAssets() external view returns (address[] memory, bool[] memory) {
        address[] memory assets = _assets.enumerate();
        bool[] memory states = new bool[](assets.length);
        for (uint i = 0; i < assets.length; ++i) {
            states[i] = _assetStates[assets[i]];
        }
        return (assets, states);
    }

    function setHonestAsset(address contractAddress) public onlyWhitelistAdmin {
        require(contractAddress != address(0), 'contract must be valid');

        _honestAsset = contractAddress;
    }

    function setHonestSavings(address contractAddress) public onlyWhitelistAdmin {
        require(contractAddress != address(0), 'contract must be valid');

        _honestSavings = contractAddress;
    }

    function addBasketAsset(address contractAddress) public onlyWhitelistAdmin {
        require(contractAddress != address(0), 'contract must be valid');

        _assets.add(contractAddress);
        _assetStates[contractAddress] = true;
    }

    function removeBasketAsset(address contractAddress) external onlyWhitelistAdmin {
        require(contractAddress != address(0), 'contract must be valid');
        require(_assets.contains(contractAddress), 'contract not included');

        _assets.remove(contractAddress);
        delete _assetStates[contractAddress];
    }

    function activateBasketAsset(address contractAddress) external onlyWhitelistAdmin {
        require(contractAddress != address(0), 'contract must be valid');
        require(_assets.contains(contractAddress), 'contract not included');

        _assetStates[contractAddress] = true;
    }

    function deactivateBasketAsset(address contractAddress) external onlyWhitelistAdmin {
        require(contractAddress != address(0), 'contract must be valid');
        require(_assets.contains(contractAddress), 'contract not included');

        _assetStates[contractAddress] = false;
    }

    function isAssetsAllActive(address[] calldata assets) external returns (bool) {
        for (uint i = 0; i < assets.length; ++i) {
            if (!_assetStates[assets[i]]) {
                return false;
            }
        }
        return true;
    }

    function balanceOf(address bAsset) external view returns (uint) {
        return _balanceOf(bAsset, Repository.ALL);
    }

    function balances() external view returns (address[] memory, uint[] memory, uint) {
        return _balances(Repository.ALL);
    }

    function distributeProportionally(address account, uint amount, Repository repository) external onlyWhitelistAdmin returns (address[] memory, uint[] memory) {
        (address[] memory assets, uint[] memory bAmounts, uint total) = _balances(repository);
        uint[] memory gapAmounts = new uint[](assets.length);
        uint gaps;
        for (uint i = 0; i < assets.length; ++i) {
            if (bAmounts[i] > 0) {
                bAmounts[i] = bAmounts[i].mul(amount).div(total);
                uint gap = (repository == Repository.SAVINGS) ? bAmounts[i] : _distributeVault(assets[i], account, bAmounts[i]);
                gapAmounts[i] = gap;
                gaps = gaps.add(gap);
            }
        }
        if (gaps > 0 && repository != Repository.VAULT) {
            _distributeSavings(account, assets, gapAmounts, gaps);
        }
        return (assets, bAmounts);
    }

    function distributeManually(address account, address[] calldata assets, uint[] calldata amounts, Repository repository) external {
        uint[] memory gapAmounts = new uint[](assets.length);
        uint gaps;
        for (uint i = 0; i < assets.length; ++i) {
            require(amounts[i] > 0, 'amount must be greater than 0');
            require(amounts[i] <= _balanceOf(assets[i], repository), 'insufficient balance');
            uint gap = (repository == Repository.SAVINGS) ? amounts[i] : _distributeVault(assets[i], account, amounts[i]);
            gapAmounts[i] = gap;
            gaps = gaps.add(gap);
        }
        if (gaps > 0) {
            _distributeSavings(account, assets, gapAmounts, gaps);
        }
    }

    function _balanceOf(address bAsset, Repository repository) public view returns (uint) {
        if (!_assetStates[bAsset]) {
            return 0;
        }
        if (repository == Repository.VAULT) {
            return ERC20Detailed(bAsset).standardBalanceOf(address(this));
        } else if (repository == Repository.SAVINGS) {
            return IHonestSavings(_honestSavings).investmentOf(bAsset);
        } else {
            return ERC20Detailed(bAsset).standardBalanceOf(address(this)).add(IHonestSavings(_honestSavings).investmentOf(bAsset));
        }
    }

    function _balances(Repository repository) public view returns (address[] memory, uint[] memory, uint) {
        uint length;
        for (uint i = 0; i < _assets.length(); ++i) {
            if (_assetStates[_assets.get(i)]) {
                ++length;
            }
        }
        address[] memory assets = new address[](length);
        uint[] memory amounts = new uint[](length);
        uint total;
        uint j = 0;
        for (uint i = 0; i < _assets.length(); ++i) {
            address asset = _assets.get(i);
            if (_assetStates[asset]) {
                assets[j] = asset;
                amounts[j] = _balanceOf(asset, repository);
                total = total.add(amounts[j]);
                ++j;
            }
        }
        return (assets, amounts, total);
    }

    function _distributeVault(address asset, address to, uint amount) internal returns (uint) {
        uint vaultBalance = ERC20Detailed(asset).standardBalanceOf(address(this));
        if (amount <= vaultBalance) {
            ERC20Detailed(asset).standardTransfer(to, amount);
            return 0;
        } else {
            ERC20Detailed(asset).standardTransfer(to, vaultBalance);
            return amount.sub(vaultBalance);
        }
    }

    function _distributeSavings(address account, address[] memory bAssets, uint[] memory borrows, uint total) internal {
        (address[] memory assets, uint[] memory bAmounts, uint bTotal) = _balances(Repository.VAULT);

        uint[] memory supplies = new uint[](assets.length);

        for (uint i = 0; i < assets.length; ++i) {
            supplies[i] = bAmounts[i].mul(total).div(bTotal);
            ERC20Detailed(assets[i]).standardApprove(_honestSavings, supplies[i]);
        }

        IHonestSavings(_honestSavings).swap(account, bAssets, borrows, assets, supplies);
    }
}