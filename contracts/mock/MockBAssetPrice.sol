pragma solidity ^0.5.0;

import {IBAssetPrice} from "../price/IBAssetPrice.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";


contract MockBAssetPrice is IBAssetPrice {
    using SafeMath for uint256;

    /** @dev query bAsset price */
    function getBAssetPrice(address _bAsset) external view returns (uint256 price, uint256 decimals){
        price = 100123450;
        decimals = 8;
    }
    /** @dev query bAsset prices */
    function getBAssetsPrice(address[] calldata _bAssets) external view returns (uint256[] memory prices, uint256[] memory decimals){
        for (uint256 i = 0; i < _bAssets.length; i++) {
            if (i % 2 == 0) {
                prices[i] = 10 ** 8;
                decimals[i] = 8;
            } else {
                prices[i] = 10 ** 8 + 100000;
                decimals[i] = 8;
            }
        }

    }
}
