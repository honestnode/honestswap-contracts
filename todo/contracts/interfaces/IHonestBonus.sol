pragma solidity ^0.6.0;

interface IHonestBonus {

    function initialize(address _priceIntegrationContract) external;

    function setPriceIntegration(address _contract) external;

    function getPriceIntegration() external view returns (address);

    function hasBonus(address asset, uint _fee) external view returns (bool);

    function calculateBonus(address _bAsset, uint _amount, uint _fee) external view returns (uint);

    function calculateBonuses(address[] calldata _bAssets, uint[] calldata _amounts, uint _fee) external view returns (uint);

    function bonusOf(address _account) external view returns (uint);

    function totalBonuses() external view returns (uint);

    function addBonus(address _account, uint _bonus) external;

    function subtractBonus(address _account, uint _bonus) external;
}