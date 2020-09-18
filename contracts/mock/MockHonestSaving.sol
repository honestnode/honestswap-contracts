pragma solidity ^0.5.0;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IHonestSavings} from "../interfaces/IHonestSavings.sol";

contract MockHonestSaving is IHonestSavings {

    using SafeMath for uint256;

    mapping(address => uint256) private savings;
    mapping(address => uint256) private shares;

    uint256 private totalSave;
    uint256 private totalShare;

    function deposit(uint256 _amount) external returns (uint256) {
        savings[msg.sender] = savings[msg.sender].add(_amount);
        uint256 newShares = _amount.mul(10);
        shares[msg.sender] = shares[msg.sender].add(newShares);
        totalSave = totalSave.add(_amount);
        totalShare = totalShare.add(newShares);

        return newShares;
    }

    function withdraw(uint256 _shares) external returns (uint256) {
        shares[msg.sender] = shares[msg.sender].sub(_shares);
        uint256 amount = _shares.div(10);
        savings[msg.sender] = savings[msg.sender].sub(amount);
        totalSave = totalSave.sub(amount);
        totalShare = totalShare.sub(_shares);

        return amount;
    }

    function savingsOf(address _account) external view returns (uint256) {
        return savings[_account];
    }

    function sharesOf(address _account) external view returns (uint256) {
        return shares[_account];
    }

    function totalSavings() external view returns (uint256) {
        return totalSave;
    }

    function totalShares() public view returns (uint256) {
        return totalShare;
    }

    function sharePrice() external view returns (uint256) {
        return totalSave.mul(uint256(1e18)).div(totalShare);
    }

    function updateApy() public {}

    function apy() external view returns (int256) {
        return 10;
    }

    function swap(address _account, address[] calldata _borrowBAssets, uint256[] calldata _borrows, address[] calldata _supplyBAssets, uint256[] calldata _supplies) external {

    }


    function investments() external view returns (address[] memory, uint256[] memory _amounts) {
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

    function initialize(address _hAssetContract, address _basketContract, address _investmentContract, address _feeContract, address _bonusContract)
    external {

    }

}
