pragma solidity ^0.5.0;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/ownership/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';

import {IHonestBasket} from "../interfaces/IHonestBasket.sol";
import {IHonestBonus} from "../interfaces/IHonestBonus.sol";
import {IHonestFee} from '../interfaces/IHonestFee.sol';
import {IHonestSavings} from "../interfaces/IHonestSavings.sol";
import {IInvestmentIntegration} from "./IInvestmentIntegration.sol";

contract HonestSavings is IHonestSavings, Ownable {

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    event SavingsDeposited(address indexed account, uint256 amount, uint256 shares);
    event SavingsRedeemed(address indexed account, uint256 shares, uint256 amount);

    address private _hAsset;
    address private _basket;
    address private _investmentIntegration;
    address private _fee;
    address private _bonus;

    mapping(address => uint256) private _savings;
    mapping(address => uint256) private _shares;

    uint256 private _totalSavings;
    uint256 private _totalShares;

    constructor(address _hAssetContract, address _basketContract,
        address _investmentContract, address _feeContract, address _bonusContract) public {
        require(_hAssetContract != address(0), "hasset contract must be valid");
        require(_basketContract != address(0), "basket contract must be valid");
        require(_investmentContract != address(0), "investment contract must be valid");
        require(_fee != address(0), "fee contract must be valid");
        require(_bonus != address(0), "bonus contract must be valid");

        _hAsset = _hAssetContract;
        _basket = _basketContract;
        _investmentIntegration = _investmentContract;
        _fee = _feeContract;
        _bonus = _bonusContract;
    }

    function setHAssetContract(address _hAssetContract) external onlyOwner {
        require(_hAssetContract != address(0), "address must be valid");
        _hAsset = _hAssetContract;
    }

    function setBasketContract(address _basketContract) external onlyOwner {
        require(_basketContract != address(0), "address must be valid");
        _basket = _basketContract;
    }

    function setInvestmentIntegrationContract(address _investmentContract) external onlyOwner {
        require(_investmentContract != address(0), "address must be valid");
        _investmentIntegration = _investmentContract;
    }

    function setFeeContract(address _feeContract) external onlyOwner {
        require(_feeContract != address(0), "address must be valid");
        _fee = _feeContract;
    }

    function setBonusContract(address _bonusContract) external onlyOwner {
        require(_bonusContract != address(0), "address must be valid");
        _bonus = _bonusContract;
    }

    function hAssetContract() external view returns (address) {
        return _hAsset;
    }

    function basketContract() external view returns (address) {
        return _basket;
    }

    function investmentIntegrationContract() external view returns (address) {
        return _investmentIntegration;
    }

    function feeContract() external view returns (address) {
        return _fee;
    }

    function bonusContract() external view returns (address) {
        return _bonus;
    }

    function deposit(uint256 _amount) external returns (uint256) {
        require(_amount > 0, "deposit must be greater than 0");

        IERC20(_hAsset).safeTransferFrom(_msgSender(), address(this), _amount);

        _savings[_msgSender()] = _savings[_msgSender()].add(_amount);
        _totalSavings = _totalSavings.add(_amount);

        (uint256[] memory shares, uint256 totalShares) = _invest(_amount);

        _shares[_msgSender()] = _shares[_msgSender()].add(totalShares);
        _totalShares = _totalShares.add(totalShares);

        emit SavingsDeposited(_msgSender(), _amount, totalShares);
        return totalShares;

    }

    function withdraw(uint256 _credits) external returns (uint256) {
        require(_credits > 0, "withdraw must be greater than 0");

        uint256 bonusShares = IHonestBonus(_bonus).bonusOf(_msgSender());
        uint256 sharesWithBonus = _shares[_msgSender()].add(bonusShares);
        require(_credits <= sharesWithBonus, "insufficient shares");

        uint256 amount = _credits.mul(_savings[_msgSender()]).div(sharesWithBonus);

        if (_credits > _shares[_msgSender()]) {
            IHonestBonus(_bonus).subtractBonus(_msgSender(), _credits.sub(_shares[_msgSender()]));
            _totalShares = _totalShares.sub(_shares[_msgSender()]);
            _shares[_msgSender()] = 0;
        } else {
            _shares[_msgSender()] = _shares[_msgSender()].sub(_credits);
            _totalShares = _totalShares.sub(_credits);
        }

        _savings[_msgSender()] = _savings[_msgSender()].sub(amount);
        _totalSavings = _totalSavings.sub(amount);

        _collect(_msgSender(), _credits, amount);
        IHonestFee(_fee).reward(_msgSender(), _sharesPercentageOf(_credits));

        emit SavingsRedeemed(_msgSender(), _credits, amount);
        return amount;
    }

    function savingsOf(address _account) external view returns (uint256) {
        require(_account != address(0), "address must be valid");
        return _savings[_account];
    }

    function sharesOf(address _account) external view returns (uint256) {
        require(_account != address(0), "address must be valid");
        return _shares[_account].add(IHonestBonus(_bonus).bonusOf(_msgSender()));
    }

    function totalSavings() external view returns (uint256) {
        return _totalSavings;
    }

    function totalShares() public view returns (uint256) {
        return _totalShares.add(IHonestBonus(_bonus).totalBonuses());
    }

    function netValue() external view returns (uint256) {
        return IInvestmentIntegration(_investmentIntegration).totalBalance().mul(uint256(1e18)).div(totalShares());
    }

    function apy() external view returns (uint256) {
        // TODO: implement
        return 0;
    }

    function swap(address _account, address[] calldata _bAssets, uint256[] calldata _borrows, uint256[] calldata _supplies) external {
        uint256 length = _bAssets.length;
        require(length == _borrows.length, "mismatch amounts length");
        require(length == _supplies.length, "mismatch amounts length");

        uint256 borrows;
        uint256 supplies;
        for(uint256 i = 0; i < length; ++i) {
            borrows = borrows.add(_borrows[i]);
            supplies = supplies.add(_supplies[i]);
            IERC20(_bAssets[i]).safeTransferFrom(_msgSender(), address(this), _supplies[i]);
            IInvestmentIntegration(_investmentIntegration).invest(_bAssets[i], _supplies[i]);

            uint256 shares = _borrows[i].mul(uint256(1e18)).div(IInvestmentIntegration(_investmentIntegration).valueOf(_bAssets[i]));
            uint256 amount = IInvestmentIntegration(_investmentIntegration).collect(_bAssets[i], shares);
            IERC20(_bAssets[i]).safeTransfer(_msgSender(), amount);
        }
        require(borrows > 0, "amounts must greater than 0");
        require(borrows == supplies, "mismatch amounts");
    }

    function investments() external view returns (address[] memory, uint256[] memory) {
        (address[] memory _assets, uint256[] memory _balances, uint256 _) = IInvestmentIntegration(_investmentIntegration).balances();
        return (_assets, _balances);
    }

    function investmentOf(address[] calldata _bAssets) external view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](_bAssets.length);
        for (uint256 i = 0; i < _bAssets.length; ++i) {
            amounts[i] = IInvestmentIntegration(_investmentIntegration).balanceOf(_bAssets[i]);
        }
        return amounts;
    }

    function _totalSharesOf(address _account) internal view returns (uint256) {
        return _shares[_account].add(IHonestBonus(_bonus).bonusOf(_account));
    }

    function _invest(uint256 _amount) internal returns (uint256[] memory, uint256) {

        IERC20(_hAsset).safeApprove(_basket, _amount);
        address[] memory assets = IInvestmentIntegration(_investmentIntegration).assets();
        uint256[] memory amounts = IHonestBasket(_basket).swapBAssets(_investmentIntegration, _amount, assets);

        uint256 length = assets.length;
        uint256[] memory shares = new uint256[](length);
        uint256 total;
        for (uint256 i = 0; i < length; ++i) {
            shares[i] = IInvestmentIntegration(_investmentIntegration).invest(assets[i], amounts[i]);
            total = total.add(shares[i]);
        }
        return (shares, total);
    }

    function _collect(address _account, uint256 _credits, uint256 _amount) internal {

        (address[] memory bAssets, uint256[] memory balances, uint256 totalBalance) =
        IInvestmentIntegration(_investmentIntegration).balances();

        uint256[] memory amounts = new uint256[](bAssets.length);
        uint256 totalAmount;
        for (uint256 i = 0; i < bAssets.length; ++i) {
            uint256 shares = _credits.mul(balances[i]).div(totalBalance);
            amounts[i] = IInvestmentIntegration(_investmentIntegration).collect(bAssets[i], shares);
            totalAmount = totalAmount.add(amounts[i]);
            IERC20(bAssets[i]).approve(_basket, amounts[i]);
        }

        IHonestBasket(_basket).distributeHAssets(_account, bAssets, amounts, totalAmount.sub(_amount));
    }

    function _sharesPercentageOf(uint256 _value) internal view returns (uint256) {
        uint256 total = _totalShares.add(IHonestBonus(_bonus).totalBonuses());
        if (total == 0) {
            return 0;
        }
        return _value.mul(uint256(1e18)).div(total);
    }
}