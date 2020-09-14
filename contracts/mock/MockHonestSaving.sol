pragma solidity ^0.5.0;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IHonestSavings} from "../interfaces/IHonestSavings.sol";

contract MockHonestSaving is IHonestSavings {

    using SafeMath for uint256;

    mapping(address => uint256) private _savings;
    mapping(address => uint256) private _shares;

    uint256 private _totalSavings;
    uint256 private _totalShares;

    function deposit(uint256 _amount) external returns (uint256) {
        _savings[msg.sender] = _savings[msg.sender].add(_amount);
        uint256 newShares = _amount.mul(10);
        _shares[msg.sender] = _shares[msg.sender].add(newShares);
        _totalSavings = _totalSavings.add(_amount);
        _totalShares = _totalShares.add(newShares);

        return newShares;
    }

    function withdraw(uint256 _credits) external returns (uint256) {
        _shares[msg.sender] = _shares[msg.sender].sub(_credits);
        uint256 amount = _credits.div(10);
        _savings[msg.sender] = _savings[msg.sender].sub(amount);
        _totalSavings = _totalSavings.sub(amount);
        _totalShares = _totalShares.sub(_credits);

        return amount;
    }

    function savingsOf(address _account) external view returns (uint256) {
        return _savings[_account];
    }

    function sharesOf(address _account) external view returns (uint256) {
        return _shares[_account];
    }

    function totalSavings() external view returns (uint256) {
        return _totalSavings;
    }

    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    function netValue() external view returns (uint256) {
        return _totalSavings.mul(uint256(1e18)).div(_totalShares);
    }

    function apy() external view returns (uint256) {
        return 10;
    }

    function swap(address _account, address[] calldata _bAssets, uint256[] calldata _borrows, uint256[] calldata _supplies) external {
    }

    function investments() external view returns (address[] memory, uint256[] memory) {
        address[] memory _assets = new address[](1);
        _assets[0] = address(0);
        uint256[] memory _balances = new uint256[](1);
        _balances[1] = 100;
        return (_assets, _balances);
    }

    function investmentOf(address[] calldata _bAssets) external view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](_bAssets.length);
        for (uint256 i = 0; i < _bAssets.length; ++i) {
            amounts[i] = i.mul(10);
        }
        return amounts;
    }

}
