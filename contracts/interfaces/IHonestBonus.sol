pragma solidity ^0.5.0;

interface IHonestBonus {

    function calculateBonus(address _bAsset) external view returns (uint256);

    function bonusOf(address _account) external view returns (uint256);

    function totalBonuses() external view returns (uint256);

    function addBonus(address _account, uint256 _bonus) external;

    function subtractBonus(address _account, uint256 _bonus) external;
}