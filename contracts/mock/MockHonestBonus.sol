pragma solidity ^0.5.0;

import "../interfaces/IHonestBonus.sol";

contract MockHonestBonus is IHonestBonus {

    function initialize(address _priceIntegrationContract) external {}

    function setPriceIntegration(address _contract) external {}

    function calculateBonus(address[] calldata _bAssets, uint256[] calldata _amounts, uint256 _fee) external view returns (uint256[] memory) {
        return new uint256[](_bAssets.length);
    }

    function bonusOf(address _account) external view returns (uint256) {
        return 0;
    }

    function totalBonuses() external view returns (uint256) {
        return 0;
    }

    function addBonus(address _account, uint256 _bonus) external {}

    function subtractBonus(address _account, uint256 _bonus) external {}
}