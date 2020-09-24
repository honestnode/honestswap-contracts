pragma solidity ^0.6.0;

import {WhitelistAdminRole} from '@openzeppelin/contracts-ethereum-package/contracts/access/roles/WhitelistAdminRole.sol';
import {SafeMath} from '@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol';
import {IERC20} from '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol';
import {ERC20} from '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol';

import {IHonestAssetManager} from "../interfaces/IHonestAssetManager.sol";
import {IHonestBonus} from "../interfaces/IHonestBonus.sol";
import {IHonestFee} from '../interfaces/IHonestFee.sol';
import {IHonestSavings} from "../interfaces/IHonestSavings.sol";
import {IInvestmentIntegration} from "../integrations/IInvestmentIntegration.sol";
import {StandardERC20} from "../utils/StandardERC20.sol";

contract HonestSavings is IHonestSavings, WhitelistAdminRole {

    using SafeERC20 for IERC20;
    using SafeMath for uint;
    using StandardERC20 for ERC20;

    event TestAmount(uint amount);
    event SavingsDeposited(address indexed account, uint amount, uint shares);
    event SavingsRedeemed(address indexed account, uint shares, uint amount);

    address private _hAsset;
    address private _hAssetManager;
    address private _investmentIntegration;
    address private _fee;
    address private _bonus;

    mapping(address => uint) private _savings;
    mapping(address => uint) private _shares;

    uint private _totalSavings;
    uint private _totalShares;
    uint private _previousApyUpdateTime;
    uint private _previousTotalValue;
    int256 private _apy;

    function initialize(
        address _hAssetContract, address _hAssetManagerContract, address _investmentContract,
        address _feeContract, address _bonusContract)
    external onlyWhitelistAdmin {
        setHAssetContract(_hAssetContract);
        setHonestAssetManager(_hAssetManagerContract);
        setInvestmentIntegrationContract(_investmentContract);
        setFeeContract(_feeContract);
        setBonusContract(_bonusContract);
        _previousApyUpdateTime = block.timestamp;
    }

    function setHAssetContract(address _hAssetContract) public onlyWhitelistAdmin {
        require(_hAssetContract != address(0), "address must be valid");
        _hAsset = _hAssetContract;
    }

    function setHonestAssetManager(address contractAddress) public onlyWhitelistAdmin {
        require(contractAddress != address(0), "address must be valid");
        _hAssetManager = contractAddress;
    }

    function setInvestmentIntegrationContract(address _investmentContract) public onlyWhitelistAdmin {
        require(_investmentContract != address(0), "address must be valid");
        _investmentIntegration = _investmentContract;
    }

    function setFeeContract(address _feeContract) public onlyWhitelistAdmin {
        require(_feeContract != address(0), "address must be valid");
        _fee = _feeContract;
    }

    function setBonusContract(address _bonusContract) public onlyWhitelistAdmin {
        require(_bonusContract != address(0), "address must be valid");
        _bonus = _bonusContract;
    }

    function hAssetContract() external view returns (address) {
        return _hAsset;
    }

    function honestAssetManager() external view returns (address) {
        return _hAssetManager;
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

    function deposit(uint _amount) external returns (uint) {
        require(_amount > 0, "deposit must be greater than 0");

        IERC20(_hAsset).safeTransferFrom(_msgSender(), address(this), _amount);

        _savings[_msgSender()] = _savings[_msgSender()].add(_amount);
        _totalSavings = _totalSavings.add(_amount);

        uint shares;
        uint bonus = IHonestBonus(_bonus).bonusOf(_msgSender());
        if (totalShares() != 0) {
            shares = _amount.add(bonus).mul(uint(1e18)).div(sharePrice());
            _invest(_amount);
        } else {
            shares = _invest(_amount).add(bonus);
        }

        _shares[_msgSender()] = _shares[_msgSender()].add(shares);
        _totalShares = _totalShares.add(shares);

        if (bonus > 0) {
            IHonestBonus(_bonus).subtractBonus(_msgSender(), bonus);
        }

        _updateApy();

        emit SavingsDeposited(_msgSender(), _amount, shares);
        return shares;
    }

    function withdraw(uint _amount) external returns (uint) {
        require(_amount > 0, "withdraw must be greater than 0");
        require(_amount <= savingsOf(_msgSender()), "insufficient savings");

        uint credits = _amount.mul(sharesOf(_msgSender())).div(savingsOf(_msgSender()));
        uint price = sharePrice();
        uint amount = credits.mul(price).div(uint(1e18));

        _shares[_msgSender()] = _shares[_msgSender()].sub(credits);
        _totalShares = _totalShares.sub(credits);

        _savings[_msgSender()] = _savings[_msgSender()].sub(_amount);
        _totalSavings = _totalSavings.sub(_amount);

        uint remaining = _distributeFee(_msgSender(), amount);

        if (remaining > 0) {
            _collect(_msgSender(), remaining, _amount);
        }

        _updateApy();

        emit SavingsRedeemed(_msgSender(), credits, amount);
        return amount;
    }

    function savingsOf(address _account) public view returns (uint) {
        require(_account != address(0), "address must be valid");
        return _savings[_account];
    }

    function sharesOf(address _account) public view returns (uint) {
        require(_account != address(0), "address must be valid");
        return _shares[_account];
    }

    function totalSavings() public view returns (uint) {
        return _totalSavings;
    }

    function totalShares() public view returns (uint) {
        return _totalShares;
    }

    function sharePrice() public view returns (uint) {
        uint pool = totalValue();
        uint total = totalShares();
        if (total == 0 || pool == 0) {
            return 0;
        }
        return pool.mul(uint(1e18)).div(total);
    }

    function totalValue() public view returns (uint) {
        return IInvestmentIntegration(_investmentIntegration).totalBalance().add(IHonestFee(_fee).totalFee());
    }

    function updateApy() public onlyWhitelistAdmin {
        _updateApy();
    }

    function _updateApy() internal {
        if (block.timestamp < _previousApyUpdateTime.add(24 hours)) {
            return;
        }
        uint currentValue = IInvestmentIntegration(_investmentIntegration).totalBalance().add(IHonestFee(_fee).totalFee());
        if (currentValue < _totalSavings) {
            return;
        }
        currentValue = currentValue - _totalSavings;
        if (currentValue == 0) {
            return;
        }
        if (currentValue >= _previousTotalValue) {
            _apy = int256(currentValue.sub(_previousTotalValue).mul(365 days).div(block.timestamp.sub(_previousApyUpdateTime)));
        } else {
            _apy = int256(-(_previousTotalValue.sub(currentValue).mul(365 days).div(block.timestamp.sub(_previousApyUpdateTime))));
        }
        _previousTotalValue = currentValue;
        _previousApyUpdateTime = block.timestamp;
    }

    function apy() external view returns (int256) {
        return _apy;
    }

    function swap(address _account, address[] calldata _bAssets, uint[] calldata _borrows, address[] calldata _sAssets,  uint[] calldata _supplies) external {
        require(_bAssets.length == _borrows.length, "mismatch borrows amounts length");
        require(_sAssets.length == _supplies.length, "mismatch supplies amounts length");

        uint supplies = _takeSwapSupplies(_sAssets, _supplies);
        uint borrows = _giveSwapBorrows(_account, _bAssets, _borrows);

        require(borrows > 0, "amounts must greater than 0");
//        require(borrows == supplies, "mismatch amounts");
    }

    function _takeSwapSupplies(address[] memory _sAssets, uint[] memory _supplies) internal returns (uint) {
        uint supplies;
        for (uint i = 0; i < _sAssets.length; ++i) {
            if (_supplies[i] == 0) {
                continue;
            }
            uint amount = ERC20(_sAssets[i]).resume(_supplies[i]);
            IERC20(_sAssets[i]).safeTransferFrom(_msgSender(), address(this), amount);
            IERC20(_sAssets[i]).safeApprove(_investmentIntegration, amount);
            IInvestmentIntegration(_investmentIntegration).invest(_sAssets[i], amount);
            supplies = supplies.add(_supplies[i]);
        }
        return supplies;
    }

    function _giveSwapBorrows(address _account, address[] memory _bAssets, uint[] memory _borrows) internal returns (uint) {
        uint borrows;
        for (uint i = 0; i < _bAssets.length; ++i) {
            if (_borrows[i] == 0) {
                continue;
            }
            uint shares = _borrows[i].mul(uint(1e18)).div(IInvestmentIntegration(_investmentIntegration).priceOf(_bAssets[i]));
            uint amount = IInvestmentIntegration(_investmentIntegration).collect(_bAssets[i], shares);
            IERC20(_bAssets[i]).safeTransfer(_account, ERC20(_bAssets[i]).resume(amount));
            borrows = borrows.add(_borrows[i]);
        }
        return borrows;
    }

    function investments() external view returns (address[] memory, uint[] memory, uint) {
        address[] memory assets = IInvestmentIntegration(_investmentIntegration).assets();
        uint[] memory amounts = new uint[](assets.length);
        uint total;
        for (uint i = 0; i < assets.length; ++i) {
            amounts[i] = IInvestmentIntegration(_investmentIntegration).balanceOf(assets[i]);
            total = total.add(amounts[i]);
        }
        return (assets, amounts, total);
    }

    function investmentOf(address bAsset) external view returns (uint) {
        return IInvestmentIntegration(_investmentIntegration).balanceOf(bAsset);
    }

    function _invest(uint _amount) internal returns (uint) {
        IERC20(_hAsset).safeApprove(_hAssetManager, _amount);
        address[] memory assets = IInvestmentIntegration(_investmentIntegration).assets();
        uint[] memory amounts = IHonestAssetManager(_hAssetManager).deposit(address(this), _amount);

        uint total;
        for (uint i = 0; i < assets.length; ++i) {
            if (amounts[i] > 0) {
                uint actualAmount = ERC20(assets[i]).resume(amounts[i]);
                IERC20(assets[i]).safeApprove(_investmentIntegration, actualAmount);
                total = total.add(IInvestmentIntegration(_investmentIntegration).invest(assets[i], actualAmount));
            }
        }
        return total;
    }

    function _collect(address _account, uint _expected, uint _amount) internal returns (uint) {
        (address[] memory bAssets, uint[] memory balances, uint totalBalance, uint price) =
        IInvestmentIntegration(_investmentIntegration).shares();
        require(totalBalance > 0, 'unexpected total balance');

        uint credits = _expected.mul(uint(1e18)).div(price);

        uint[] memory amounts = new uint[](bAssets.length);
        uint totalAmount;
        // because of the percentage calculation, the shares may be gap from actual balances
        uint gap;
        for (uint i = 0; i < bAssets.length; ++i) {
            uint shares = credits.mul(balances[i]).div(totalBalance);
            if (shares == 0) {
                continue;
            }
            if (shares >= balances[i]) {
                gap += shares.sub(balances[i]);
                shares = balances[i];
            } else if (balances[i] >= shares.add(gap)) {
                shares = shares.add(gap);
                gap = 0;
            } else {
                gap = gap.sub(balances[i].sub(shares));
                shares = balances[i];
            }
            amounts[i] = IInvestmentIntegration(_investmentIntegration).collect(bAssets[i], shares);
            totalAmount = totalAmount.add(amounts[i]);
            amounts[i] = ERC20(bAssets[i]).resume(amounts[i]);
            IERC20(bAssets[i]).safeApprove(_hAssetManager, amounts[i]);
        }
        //require(gap == 0, 'failed in gap share');
        if (totalAmount > _amount) {
            IHonestAssetManager(_hAssetManager).withdraw(_account, bAssets, amounts, totalAmount.sub(_amount));
        } else {
            IHonestAssetManager(_hAssetManager).withdraw(_account, bAssets, amounts, 0);
        }
        return totalAmount;
    }

    function _distributeFee(address _account, uint _amount) internal returns (uint) {
        require(_amount > 0, 'amount must greater than 0');
        uint totalFee = IHonestFee(_fee).totalFee();
        if (_amount > totalFee) {
            IHonestFee(_fee).reward(_account, totalFee);
            return _amount.sub(totalFee);
        } else {
            IHonestFee(_fee).reward(_account, _amount);
            return 0;
        }
    }
}