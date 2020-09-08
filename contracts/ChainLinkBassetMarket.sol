pragma solidity 0.5.16;

import {IBassetMarket} from "./interface/IBassetMarket.sol";
import {InitializableModule} from "./common/InitializableModule.sol";

import {Initializable} from "@openzeppelin/upgrades/contracts/Initializable.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.5/interfaces/AggregatorV3Interface.sol";

/**
 * @title   ChainLinkBassetMarket
 * @author  HonestSwap. Ltd.
 * @notice  BassetMarket save the current price of all the bAssets
 * @dev     VERSION: 1.0
 */
contract ChainLinkBassetMarket is Initializable, IBassetMarket, InitializableModule {

    using SafeMath for uint256;

    // Price of each bAsset
    mapping(address => address) bAssetsAggregators;
    AggregatorV3Interface ethUsdAggregator;

    uint8 MAX_DECIMALS = 8;

    // Price of each bAsset
    mapping(address => uint256) public bAssetPrices;

    function initialize(
        address _nexus,
        address calldata _ethUsdAggregator,
        address[] calldata _bAssets,
        address[] calldata _aggregators
    )
    external
    initializer
    {
        InitializableModule._initialize(_nexus);

        require(_ethUsdAggregator != address(0), "Must be a valid _ethUsdAggregator");
        require(_bAssets.length > 0 && _bAssets.length == _aggregators.length, "Must initialise with some bAssets");

        ethUsdAggregator = AggregatorV3Interface(_ethUsdAggregator);

        for (uint256 i = 0; i < _bAssets.length; i++) {
            bAssetsAggregators[_bAssets[i]] = _aggregators[i];
        }
    }

    /**
     * @dev Query bAsset's current price
     * @param _bAsset    bAsset address
     */
    function getBassetPrice(address _bAsset) external view
    returns (uint256 price, uint8 decimals){
        require(_bAsset != address(0), "Must be a valid _bAsset");

        address aggregator = bAssetsAggregators[_bAsset];
        require(aggregator != address(0), "Must be a valid bAsset aggregator");

        (uint256 ethUsdPrice, uint8 ethUsdDecimals) = _queryLatestPrice(ethUsdAggregator);
        AggregatorV3Interface bAssetEthAggregator = AggregatorV3Interface(aggregator);
        (uint256 bAssetEthPrice, uint8 bAssetEthDecimals) = _queryLatestPrice(bAssetEthAggregator);
        price = bAssetEthPrice.mul(ethUsdPrice);
        decimals = ethUsdDecimals + bAssetEthDecimals;
        if (decimals > MAX_DECIMALS) {
            price = price.div(10 ** (decimals.sub(MAX_DECIMALS)));
            decimals = MAX_DECIMALS;
        }
    }

    function getBassetsPrice(address[] _bAssets) external view
    returns (uint256[] prices, uint8[] decimals){
        uint256 len = _bAssets.length;
        require(len > 0, "Input array is empty");

        uint256[] prices = new uint256[](len);
        uint8[] decimals = new uint8[](len);

        (uint256 ethUsdPrice, uint8 ethUsdDecimals) = _queryLatestPrice(ethUsdAggregator);

        for (uint256 i = 0; i < len; i++) {
            address bAsset = _bAssets[i];

            address aggregator = bAssetsAggregators[bAsset];
            require(aggregator != address(0), "Must be a valid bAsset aggregator");

            AggregatorV3Interface bAssetEthAggregator = AggregatorV3Interface(aggregator);
            (uint256 bAssetEthPrice, uint8 bAssetEthDecimals) = _queryLatestPrice(bAssetEthAggregator);
            price = bAssetEthPrice.mul(ethUsdPrice);
            uint8 decimalsSum = ethUsdDecimals + bAssetEthDecimals;
            if (decimalsSum > MAX_DECIMALS) {
                price = price.div(10 ** (decimalsSum - MAX_DECIMALS));
                decimalsSum = MAX_DECIMALS;
            }

            prices[i] = price;
            decimals[i] = decimalsSum;
        }
    }

    /**
     * @dev Query bAsset's current price with ChainLink
     * @param _aggregator
     */
    function _queryLatestPrice(AggregatorV3Interface _aggregator) internal
    returns (uint256 price, uint8 decimals) {
        decimals = aggregator.decimals();
        (uint80 roundID,
        int256 answer,
        uint256 startedAt,
        uint256 timeStamp,
        uint80 answeredInRound
        ) = aggregatorInterface.latestRoundData();
        price = answer;
    }

//    /**
//     * @dev Update bAsset's current price
//     * @param _bAsset    bAsset address
//     * @param _price    bAsset new price
//     */
//    function setBassetPrice(address _bAsset, uint256 _price)
//    external
//    onlyGovernor
//    {
//        require(_bAsset != address(0), "Must be a valid _bAsset");
//        require(_price > 0, "Price must not > 0");
//
//        uint256 oldPrice = bAssetPrices[_bAsset];
//        bAssetPrices[_bAsset] = _price;
//
//        emit BassetPriceUpdated(_bAsset, _price, oldPrice);
//    }
//
//    function setBassetPrices(address[] _bAssets, uint256[] _prices)
//    external
//    onlyGovernor
//    {
//        uint256 len = _prices.length;
//        require(len > 0 && len == _bAssets.length, "Input array mismatch");
//
//        for (uint256 i = 0; i < len; i++) {
//            address bAsset = _bAssets[i];
//            uint256 price = _prices[i];
//            if (price > 0 && bAsset != address(0)) {
//                // update price
//                uint256 oldPrice = bAssetPrices[bAsset];
//                bAssetPrices[bAsset] = price;
//
//                emit BassetPriceUpdated(bAsset, price, oldPrice);
//            }
//        }
//    }
}
