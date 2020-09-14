pragma solidity ^0.5.0;

import {WhitelistedRole} from '@openzeppelin/contracts/access/roles/WhitelistedRole.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {EnumerableSet} from '@openzeppelin/contracts/utils/EnumerableSet.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import {IInvestmentIntegration} from "./IInvestmentIntegration.sol";

interface yTokenV2 {
    function deposit(uint256 _amount) external;

    function withdraw(uint256 _shares) external;

    function getPricePerFullShare() external view returns (uint256);
}

contract YearnV2Integration is IInvestmentIntegration, WhitelistedRole, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _assets;
    mapping(address => address) private _contracts;

    constructor() public {
        _addWhitelisted(_msgSender());
    }

    function assets() external view returns (address[] memory) {
        return _assets.enumerate();
    }

    function addAsset(address _address, address _yAddress) external onlyWhitelisted {
        require(_address != address(0), 'address must be valid');
        require(_yAddress != address(0), 'yAddress must be valid');

        if (!_assets.contains(_address)) {
            _assets.add(_address);
            _contracts[_address] = _yAddress;
        }
    }

    function removeAsset(address _address) external onlyWhitelisted {
        require(_address != address(0), 'address must be valid');

        _assets.remove(_address);
        delete _contracts[_address];
    }

    function invest(address _asset, uint256 _amount) external onlyWhitelisted nonReentrant returns (uint256) {
        require(_amount > 0, "invest must greater than 0");

        IERC20(_asset).safeTransferFrom(_msgSender(), address(this), _amount);

        address yToken = _contractOf(_asset);
        uint256 before = IERC20(yToken).balanceOf(address(this));
        IERC20(_asset).safeApprove(yToken, _amount);
        yTokenV2(yToken).deposit(_amount);

        uint256 shares = IERC20(yToken).balanceOf(address(this)).sub(before);
        return shares;
    }

    function collect(address _asset, uint256 _shares) external onlyWhitelisted returns (uint256) {
        require(_shares > 0, "shares must greater than 0");

        yTokenV2 yToken = yTokenV2(_contractOf(_asset));
        uint256 amount = _shares.mul(yToken.getPricePerFullShare()).div(uint256(1e18));
        yToken.withdraw(_shares);

        require(amount <= IERC20(_asset).balanceOf(address(this)), "insufficient balance");
        IERC20(_asset).safeTransfer(_msgSender(), amount);

        return amount;
    }

    function valueOf(address _bAsset) external view returns (uint256) {
        address yToken = _contractOf(_bAsset);
        return yTokenV2(yToken).getPricePerFullShare();
    }

    function balanceOf(address _asset) external view returns (uint256) {
        return _balanceOf(_asset);
    }

    function balances() external view returns (address[] memory, uint256[] memory, uint256) {
        uint256 length = _assets.length();
        uint256[] memory aBalances = new uint256[](length);
        uint256 totalBalances;
        for (uint256 i = 0; i < length; ++i) {
            aBalances[i] = _balanceOf(_assets.get(i));
            totalBalances = totalBalances.add(aBalances[i]);
        }
        return (_assets.enumerate(), aBalances, totalBalances);
    }

    function totalBalance() external view returns (uint256) {
        uint256 length = _assets.length();
        uint256 balance = 0;

        for (uint256 i = 0; i < length; ++i) {
            balance.add(_balanceOf(_assets.get(i)));
        }
        return balance;
    }

    function _contractOf(address _asset) internal view returns (address) {
        address yToken = _contracts[_asset];
        require(yToken != address(0), "can not find any available investment contract");
        return yToken;
    }

    function _balanceOf(address _asset) internal view returns (uint256) {
        address yToken = _contractOf(_asset);

        uint256 shares = IERC20(yToken).balanceOf(address(this));
        return yTokenV2(yToken).getPricePerFullShare().mul(shares).div(uint256(1e18));
    }
}