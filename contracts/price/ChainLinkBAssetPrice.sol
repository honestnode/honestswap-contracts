pragma solidity 0.5.16;

import {IBAssetPrice} from "./IBAssetPrice.sol";
import {InitializableModule} from "../common/InitializableModule.sol";

import {Initializable} from "@openzeppelin/upgrades/contracts/Initializable.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.5/interfaces/AggregatorV3Interface.sol";

/**
 * @title   ChainLinkBAssetPrice
 * @author  HonestSwap. Ltd.
 * @notice  BassetMarket save the current price of all the bAssets
 * @dev     VERSION: 1.0
 */
contract ChainLinkBAssetPrice is Initializable, IBAssetPrice, InitializableModule {

    using SafeMath for uint256;

    // Price of each bAsset
    mapping(address => address) bAssetsAggregators;
    AggregatorV3Interface ethUsdAggregator;

    uint8 MAX_DECIMALS = 8;

    // Price of each bAsset
    mapping(address => uint256) public bAssetPrices;

    function initialize(
        address _nexus,
        address _ethUsdAggregator,
        address[] calldata _bAssets,
        address[] calldata _aggregators
    )
    external
    initializer
    {
        //        InitializableModule._initialize(_nexus);

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
    function getBAssetPrice(address _bAsset) external view
    returns (uint256 price, uint256 decimals){
        require(_bAsset != address(0), "Must be a valid _bAsset");

        address aggregator = bAssetsAggregators[_bAsset];
        require(aggregator != address(0), "Must be a valid bAsset aggregator");

        (uint256 ethUsdPrice, uint256 ethUsdDecimals) = _queryLatestPrice(ethUsdAggregator);
        AggregatorV3Interface bAssetEthAggregator = AggregatorV3Interface(aggregator);
        (uint256 bAssetEthPrice, uint256 bAssetEthDecimals) = _queryLatestPrice(bAssetEthAggregator);
        price = bAssetEthPrice.mul(ethUsdPrice);
        decimals = ethUsdDecimals + bAssetEthDecimals;
        if (decimals > MAX_DECIMALS) {
            price = price.div(10 ** (decimals.sub(MAX_DECIMALS)));
            decimals = MAX_DECIMALS;
        }
    }

    function getBAssetsPrice(address[] calldata _bAssets) external view
    returns (uint256[] memory prices, uint256[] memory decimals){
        uint256 len = _bAssets.length;
        require(len > 0, "Input array is empty");

        prices = new uint256[](len);
        decimals = new uint256[](len);

        (uint256 ethUsdPrice, uint256 ethUsdDecimals) = _queryLatestPrice(ethUsdAggregator);

        for (uint256 i = 0; i < len; i++) {
            address bAsset = _bAssets[i];

            address aggregator = bAssetsAggregators[bAsset];
            require(aggregator != address(0), "Must be a valid bAsset aggregator");

            AggregatorV3Interface bAssetEthAggregator = AggregatorV3Interface(aggregator);
            (uint256 bAssetEthPrice, uint256 bAssetEthDecimals) = _queryLatestPrice(bAssetEthAggregator);
            uint256 price = bAssetEthPrice.mul(ethUsdPrice);
            uint256 decimalsSum = ethUsdDecimals.add(bAssetEthDecimals);
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
     * @param _aggregator ChainLink aggregator
     */
    function _queryLatestPrice(AggregatorV3Interface _aggregator) internal view
    returns (uint256 price, uint256 decimals) {
        decimals = uint256(_aggregator.decimals());
        (uint80 roundID,
        int256 answer,
        uint256 startedAt,
        uint256 timeStamp,
        uint80 answeredInRound
        ) = _aggregator.latestRoundData();
        price = uint256(answer);
    }

}
