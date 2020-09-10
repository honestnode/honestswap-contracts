pragma solidity ^0.5.0;

import '@openzeppelin/contracts/ownership/Ownable.sol';
import "./IHNTRewards.sol";

contract HNTRewardsFactory is IHNTRewards, Ownable {

    address public rewardsContract;
    IHNTRewards private _delegator;

    constructor(address _contract) public {
        setDelegator(_contract);
    }

    function setDelegator(address _contract) public onlyOwner {
        require(_contract != address(0), "Address must be valid");
        rewardsContract = _contract;
        _delegator = IHNTRewards(_contract);
    }

    function setToken(address _token) external onlyOwner {
        _delegator.setToken(_token);
    }

    function totalSavings() external view returns (uint256) {
        return _delegator.totalSavings();
    }

    function totalRewards() external view returns (uint256) {
        return _delegator.totalRewards();
    }

    function savingsOf(address _account) external view returns (uint256) {
        return _delegator.savingsOf(_account);
    }

    function rewardsOf(address _account) external view returns (uint256) {
        return _delegator.rewardsOf(_account);
    }

    function sharesOf(address _account) external view returns (uint256) {
        return _delegator.sharesOf(_account);
    }

    function deposit(uint256 _amount) external returns (bool) {
        return _delegator.deposit(_amount);
    }

    function redeem(uint256 _amount) external returns (bool) {
        return _delegator.redeem(_amount);
    }
}