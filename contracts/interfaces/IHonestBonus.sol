pragma solidity ^0.5.0;

interface IHonestBonus {

    function initialize(address _priceIntegrationContract) external;

    function setPriceIntegration(address _contract) external;

    function getPriceIntegration() external view returns (address);

    function hasBonus(address asset, uint256 _fee) external view returns (bool);

    function calculateBonus(address _bAsset, uint256 _amount, uint256 _fee) external view returns (uint256);

    function calculateBonuses(address[] calldata _bAssets, uint256[] calldata _amounts, uint256 _fee) external view returns (uint256);

    function bonusOf(address _account) external view returns (uint256);

    function totalBonuses() external view returns (uint256);

    function addBonus(address _account, uint256 _bonus) external;

    function subtractBonus(address _account, uint256 _bonus) external;
}