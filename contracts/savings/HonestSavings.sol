pragma solidity ^0.5.0;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/ownership/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';

import "../interfaces/IHonestBasket.sol";
import "../interfaces/IHonestSavings.sol";
import "./IInvestmentIntegration.sol";

contract HonestSavings is IHonestSavings, Ownable {

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    event SavingsDeposited(address indexed account, uint256 amount, uint256 shares);
    event SavingsRedeemed(address indexed account, uint256 shares, uint256 amount);

    address private _hAsset;
    address private _basket;
    address private _investmentIntegration;

    mapping(address => uint256) private _savings;
    mapping(address => uint256) private _shares;

    uint256 private _totalSavings;
    uint256 private _totalShares;

    constructor(address _hAssetContract, address _basketContract, address _investmentContract) public {
        require(_hAssetContract != address(0), "hasset contract must be valid");
        require(_basketContract != address(0), "basket contract must be valid");
        require(_investmentContract != address(0), "investment contract must be valid");

        _hAsset = _hAssetContract;
        _basket = _basketContract;
        _investmentIntegration = _investmentContract;
    }

    function setHAsset(address _hAssetContract) external onlyOwner {
        require(_hAssetContract != address(0), "address must be valid");
        _hAsset = _hAssetContract;
    }

    function setBasket(address _basketContract) external onlyOwner {
        require(_basketContract != address(0), "address must be valid");
        _basket = _hAssetContract;
    }

    function setInvestmentIntegration(address _investmentContract) external onlyOwner {
        require(_investmentContract != address(0), "address must be valid");
        _investmentIntegration = _investmentContract;
    }

    function hAsset() external view returns (address) {
        return _hAsset;
    }

    function basket() external view returns (address) {
        return _basket;
    }

    function investmentIntegration() external view returns (address) {
        return _investmentIntegration;
    }

    function deposit(uint256 _amount) external returns (uint256) {
        require(_amount > 0, "deposit must be greater than 0");

        IERC20(_hAsset).safeTransferFrom(_msgSender(), address(this), _amount);

        _savings[_msgSender()] = _savings[_msgSender()].add(_amount);
        _totalSavings = _totalSavings.add(_amount);

        uint256 shares = _savingsToShares(_amount);
        _shares[_msgSender()] = _shares[_msgSender()].add(shares);
        _totalShares = _totalShares.add(shares);

        _invest(_msgSender(), _amount);

        emit SavingsDeposited(_msgSender(), _amount, shares);
        return shares;

    }

    function withdraw(uint256 _credits) external returns (uint256) {
        require(_credits > 0, "withdraw must be greater than 0");
        require(_credits <= _shares[_msgSender()], "insufficient shares");

        _shares[_msgSender()] = _shares[_msgSender()].sub(_credits);
        _totalShares = _totalShares.sub(_credits);

        uint256 amount = _sharesToSavings(_credits);
        _savings[_msgSender()] = _savings[_msgSender()].sub(amount);
        _totalSavings = _totalSavings.sub(amount);

        _collect(_msgSender(), amount);

        IERC20(_hAsset).safeTransfer(_msgSender(), amount);

        emit SavingsRedeemed(_msgSender(), _credits, amount);
        return amount;
    }

    function savingsOf(address _account) external view returns (uint256) {
        require(_account != address(0), "address must be valid");
        return _savings[_account];
    }

    function sharesOf(address _account) external view returns (uint256) {
        require(_account != address(0), "address must be valid");
        return _shares[_account];
    }

    function totalSavings() external view returns (uint256) {
        return _totalSavings;
    }

    function totalShares() external view returns (uint256) {
        return _totalShares;
    }

    function netValue() external view returns (uint256) {
        return _netValue();
    }

    function apy() external view returns (uint256) {
        // TODO: implement
        return 0;
    }

    function borrow(address _account, address[] calldata _bAssets, uint256[] calldata _amounts) external returns (uint256) {
        // TODO: implement
        return 0;
    }

    function supply(uint256 _amounts) external returns (uint256) {
        // TODO: implement
        return 0;
    }

    function _netValue() internal view returns (uint256) {
        return IInvestmentIntegration(_investmentIntegration).totalBalance().mul(1e18).div(_totalSavings);
    }

    function _savingsToShares(uint256 _amount) internal view returns (uint256) {
        return _amount.mul(1e18).div(_netValue());
    }

    function _sharesToSavings(uint256 _credits) internal view returns (uint256) {
        return _credits.mul(_netValue()).div(1e18);
    }

    function _invest(address _account, uint256 _amount) internal {

        IERC20(_hAsset).safeApprove(_basket, _amount);
        address[] memory assets = IInvestmentIntegration(_investmentIntegration).assets();
        uint256[] memory amounts = IHonestBasket(_basket).swapBAssets(_investmentIntegration, _amount, assets);

        int length = assets.length;
        for (int i = 0; i < length; ++i) {
            IInvestmentIntegration(_investmentIntegration).invest(assets[i], amount);
            // TODO: save the shares
        }
    }

    function _collect(address _account, uint256 _credits) internal {
        // TODO:
        // 1. find current investment bAssets rate
        // 2. for(rate in 1) {
        //   IInvestmentIntegration(_investmentIntegration).collect(_shares * rate);
        // }
        // 3. HAsset.mintMultiTo(_account, [2])
    }
}