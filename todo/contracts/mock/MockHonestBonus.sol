pragma solidity ^0.6.0;

import {IHonestBonus} from "../interfaces/IHonestBonus.sol";

contract MockHonestBonus is IHonestBonus {

    function initialize(address _priceIntegrationContract) external {}

    function setPriceIntegration(address _contract) external {}

    function getPriceIntegration() external view returns (address) {
        return address(0);
    }

    function hasBonus(address asset, uint _fee) external view returns (bool) {
        return false;
    }

    function calculateBonus(address _bAsset, uint _amount, uint _fee) external view returns (uint) {
        return 0;
    }

    function calculateBonuses(address[] calldata _bAssets, uint[] calldata _amounts, uint _fee) external view returns (uint) {
        return 0;
    }

    function bonusOf(address _account) external view returns (uint) {
        return 0;
    }

    function totalBonuses() external view returns (uint) {
        return 0;
    }

    function addBonus(address _account, uint _bonus) external {}

    function subtractBonus(address _account, uint _bonus) external {}
}