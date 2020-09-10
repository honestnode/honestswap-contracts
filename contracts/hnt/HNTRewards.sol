pragma solidity ^0.5.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/ownership/Ownable.sol';
import "./IHNTRewards.sol";

contract HNTRewords is IHNTRewards, Ownable {

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    uint256 public sharesRatio = 1e4;
    uint public lastRedeemTime = 0;
    address public token;

    mapping (address => uint256) private _savings;
    uint256 private _totalSavings;

    constructor(address _token) public {
        require(_token != address(0), "Address must be valid");
        token = _token;
    }

    function setToken(address _token) external onlyOwner {
        require(_token != address(0), "Address must be valid");
        token = _token;
    }

    function totalSavings() external view returns (uint256) {
        return _totalSavings;
    }

    function totalRewards() external view returns (uint256) {
        return _totalRewards();
    }

    function savingsOf(address _account) external view returns (uint256) {
        require(_account != address(0), "Address must be valid");
        return _savings[_account];
    }

    function rewardsOf(address _account) external view returns (uint256) {
        require(_account != address(0), "Address must be valid");
        return _rewardsOf(_account);
    }

    function sharesOf(address _account) external view returns (uint256) {
        require(_account != address(0), "Address must be valid");
        if (_totalSavings == 0) {
            return 0;
        }
        uint256 savings = _savings[_msgSender()];
        return savings.mul(sharesRatio).div(_totalSavings);
    }

    function deposit(uint256 _amount) external returns (bool) {
        require(_amount > 0, "deposit must be greater than 0");
        _totalSavings = _totalSavings.add(_amount);
        _savings[_msgSender()] = _savings[_msgSender()].add(_amount);
        return true;
    }

    function redeem(uint256 _amount) external returns (bool) {
        require(_amount > 0, "redeem must be greater than 0");
        uint256 savings = _savings[_msgSender()];
        require(_amount <= savings, "insufficient savings");

        IERC20(token).safeTransfer(_msgSender(), _amount);
        return true;
    }

    function _totalRewards() internal view returns (uint256) {
        // TODO:
        return 0;
    }

    function _rewardsOf(address _account) internal view returns (uint256) {
        return _sharesOf(_account).mul(_totalRewards()).div(sharesRatio);
    }

    function _sharesOf(address _account) internal view returns (uint256) {
        if (_totalSavings == 0) {
            return 0;
        }
        uint256 savings = _savings[_account];
        return savings.mul(sharesRatio).div(_totalSavings);
    }

    function _deliveryRewards() internal {

    }
}