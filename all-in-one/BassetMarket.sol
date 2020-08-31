pragma solidity 0.5.16;

import {IBassetMarket} from "./interface/IBassetMarket.sol";
import {Module} from "./common/Module.sol";

/**
 * @title   BassetMarket
 * @author  HonestSwap. Ltd.
 * @notice  BassetMarket save the current price of all the bAssets
 * @dev     VERSION: 1.0
 */
contract BassetMarket is IBassetMarket, Module {

    event BassetPriceUpdated(address indexed bAsset, uint256 newPrice, uint256 oldPrice);

    // Price of each bAsset
    mapping(address => uint256) public bAssetPrices;

    /**
     * @dev Query bAsset's current price
     * @param _bAsset    bAsset address
     */
    function getBassetPrice(address _bAsset) external view
    returns (uint256 price){
        require(_bAsset != address(0), "Must be a valid _bAsset");

        uint256 price = bAssetPrices[_bAsset];
        return price;
    }

    function getBassetsPrice(address[] _bAssets) external view
    returns (uint256[] prices){
        uint256 len = _bAssets.length;
        require(len > 0, "Input array is empty");

        uint256[] prices = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            address bAsset = _bAssets[i];
            uint256 price = 1;
            prices[i] = price;
        }
        return prices;
    }

    /**
     * @dev Update bAsset's current price
     * @param _bAsset    bAsset address
     * @param _price    bAsset new price
     */
    function setBassetPrice(address _bAsset, uint256 _price)
    external
    onlyGovernor
    {
        require(_bAsset != address(0), "Must be a valid _bAsset");
        require(_price > 0, "Price must not > 0");

        uint256 oldPrice = bAssetPrices[_bAsset];
        bAssetPrices[_bAsset] = _price;

        emit BassetPriceUpdated(_bAsset, _price, oldPrice);
    }

    function setBassetPrices(address _bAssets, uint256 _prices)
    external
    onlyGovernor
    {
        uint256 len = _prices.length;
        require(len > 0 && len == _bAssets.length, "Input array mismatch");

        for (uint256 i = 0; i < len; i++) {
            address bAsset = _bAssets[i];
            uint256 price = _prices[i];
            if (price > 0 && bAsset != address(0)) {
                // update price
                uint256 oldPrice = bAssetPrices[bAsset];
                bAssetPrices[bAsset] = price;

                emit BassetPriceUpdated(bAsset, price, oldPrice);
            }
        }
    }
}
