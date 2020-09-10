pragma solidity ^0.5.0;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/ownership/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';

import "../interfaces/IHonestSavings.sol";

contract HonestSavings is IHonestSavings, Ownable {

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    event SavingsDeposited(address indexed account, uint256 amount, uint256 shares);
    event SavingsRedeemed(address indexed account, uint256 shares, uint256 amount);

    address private _hAsset;

    mapping(address => uint256) private _savings;
    mapping(address => uint256) private _shares;

    uint256 private _totalSavings;
    uint256 private _totalShares;

    constructor(address _hAssetContract) public {
        require(_hAssetContract != address(0), "address must be valid");
        _hAsset = _hAssetContract;
    }

    function setHAsset(address _hAssetContract) external onlyOwner {
        require(_hAssetContract != address(0), "address must be valid");
        _hAsset = _hAssetContract;
    }

    function hAsset() external view returns (address) {
        return _hAsset;
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
        return 1e18;
    }

    function _savingsToShares(uint256 _amount) internal view returns (uint256) {
        return _amount.mul(1e18).div(_netValue());
    }

    function _sharesToSavings(uint256 _credits) internal view returns (uint256) {
        return _credits.mul(_netValue()).div(1e18);
    }

    function _invest(address _account, uint256 _amount) internal {
        // TODO: implement
    }

    function _collect(address _account, uint256 _amount) internal {
        // TODO: implement
    }
}