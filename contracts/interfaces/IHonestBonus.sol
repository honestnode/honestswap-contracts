pragma solidity ^0.5.0;

interface IHonestBonus {

    function hasBonus(address _bAsset) external view returns (bool);

    function bonusOf(address _account) external view returns (uint256);

    function totalBonus() external view returns (uint256);

    function addBonus(address _account, uint256 _amount) external returns (uint256);

    function claimRewards(address _account) external returns (uint256);
}