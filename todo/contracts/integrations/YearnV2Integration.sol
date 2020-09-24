pragma solidity ^0.6.0;

import {WhitelistedRole} from '@openzeppelin/contracts-ethereum-package/contracts/access/roles/WhitelistedRole.sol';
import {SafeMath} from '@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol';
import {IERC20} from '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol';
import {ERC20} from '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol';
import {EnumerableSet} from '@openzeppelin/contracts-ethereum-package/contracts/utils/EnumerableSet.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol';
import {IInvestmentIntegration} from "./IInvestmentIntegration.sol";
import {StandardERC20} from "../utils/StandardERC20.sol";

interface yTokenV2 {
    function deposit(uint _amount) external;

    function withdraw(uint _shares) external;

    function getPricePerFullShare() external view returns (uint);
}

contract YearnV2Integration is IInvestmentIntegration, WhitelistedRole, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using SafeMath for uint;
    using StandardERC20 for ERC20;

    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _assets;
    mapping(address => address) private _contracts;

    function initialize(address[] calldata _addresses, address[] calldata _yAddresses) external onlyWhitelistAdmin {
        for (uint i = 0; i < _addresses.length; ++i) {
            addAsset(_addresses[i], _yAddresses[i]);
        }
    }

    function assets() external view returns (address[] memory) {
        return _assets.enumerate();
    }

    function addAsset(address _address, address _yAddress) public onlyWhitelistAdmin {
        require(_address != address(0), 'address must be valid');
        require(_yAddress != address(0), 'yAddress must be valid');

        if (!_assets.contains(_address)) {
            _assets.add(_address);
            _contracts[_address] = _yAddress;
        }
    }

    function removeAsset(address _address) external onlyWhitelistAdmin {
        require(_address != address(0), 'address must be valid');

        _assets.remove(_address);
        delete _contracts[_address];
    }

    function invest(address _asset, uint _amount) external onlyWhitelisted nonReentrant returns (uint) {
        require(_amount > 0, "invest must greater than 0");

        IERC20(_asset).safeTransferFrom(_msgSender(), address(this), _amount);

        address yToken = _contractOf(_asset);
        uint before = IERC20(yToken).balanceOf(address(this));
        IERC20(_asset).safeApprove(yToken, _amount);
        yTokenV2(yToken).deposit(_amount);

        uint shares = IERC20(yToken).balanceOf(address(this)).sub(before);
        return ERC20(yToken).standardize(shares);
    }

    function collect(address _asset, uint _shares) external onlyWhitelisted returns (uint) {
        require(_shares > 0, "shares must greater than 0");

        yTokenV2 yToken = yTokenV2(_contractOf(_asset));
        uint originShares = ERC20(address(yToken)).resume(_shares);
        uint amount = originShares.mul(yToken.getPricePerFullShare()).div(uint(1e18));

        yToken.withdraw(originShares);

        require(amount <= IERC20(_asset).balanceOf(address(this)), "insufficient balance");
        IERC20(_asset).safeTransfer(_msgSender(), amount);

        return ERC20(_asset).standardize(amount);
    }

    function priceOf(address _bAsset) external view returns (uint) {
        address yToken = _contractOf(_bAsset);
        return yTokenV2(yToken).getPricePerFullShare();
    }

    function shareOf(address _bAsset) public view returns (uint) {
        require(_assets.contains(_bAsset), 'asset not supported');

        return ERC20(_contractOf(_bAsset)).standardBalanceOf(address(this));
    }

    function shares() external view returns (address[] memory, uint[] memory, uint, uint) {
        uint[] memory credits = new uint[](_assets.length());
        uint totalShare;
        uint totalBalance;
        for (uint i = 0; i < _assets.length(); ++i) {
            credits[i] = shareOf(_assets.get(i));
            totalShare = totalShare.add(credits[i]);
            totalBalance = totalBalance.add(_balanceOf(_assets.get(i)));
        }
        return (_assets.enumerate(), credits, totalShare, totalBalance.mul(uint(1e18)).div(totalShare));
    }

    function balanceOf(address _asset) external view returns (uint) {
        return _balanceOf(_asset);
    }

    function balances() external view returns (address[] memory, uint[] memory, uint) {
        uint[] memory aBalances = new uint[](_assets.length());
        uint totalBalances;
        for (uint i = 0; i < _assets.length(); ++i) {
            aBalances[i] = _balanceOf(_assets.get(i));
            totalBalances = totalBalances.add(aBalances[i]);
        }
        return (_assets.enumerate(), aBalances, totalBalances);
    }

    function totalBalance() external view returns (uint) {
        uint balance;
        for (uint i = 0; i < _assets.length(); ++i) {
            balance = balance.add(_balanceOf(_assets.get(i)));
        }
        return balance;
    }

    function _contractOf(address _asset) internal view returns (address) {
        address yToken = _contracts[_asset];
        require(yToken != address(0), "can not find any available investment contract");
        return yToken;
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