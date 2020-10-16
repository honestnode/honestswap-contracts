// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;
//
//import {Initializable} from '@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol';
//import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
//import {IAssetPriceIntegration} from "./IAssetPriceIntegration.sol";
//import {AbstractHonestContract} from "../AbstractHonestContract.sol";
//import {IHonestConfiguration} from '../interfaces/IHonestConfiguration.sol';
//
// Reference from @chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol
interface AggregatorV3Interface {

    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}
//
//contract ChainlinkIntegration is IAssetPriceIntegration, AbstractHonestContract {
//
//    using SafeMath for uint;
//
//    address private _ethUsdFeeds;
//    address private _honestConfiguration;
//
//    function initialize(address owner, address honestConfiguration, address ethUsdFeeds) public initializer() {
//        require(owner != address(0), 'ChainlinkIntegration.initialize: owner address must be valid');
//        require(honestConfiguration != address(0), 'ChainlinkIntegration.initialize: configuration address must be valid');
//        require(ethUsdFeeds != address(0), 'ChainlinkIntegration.initialize: ETH price feeds must be valid');
//
//        super.initialize(owner);
//        _honestConfiguration = honestConfiguration;
//        _ethUsdFeeds = ethUsdFeeds;
//    }
//
//    function honestConfiguration() external override view returns (address) {
//        return _honestConfiguration;
//    }
//
//    function ethPriceFeeds() external override view returns (address) {
//        return _ethUsdFeeds;
//    }
//
//    function getPrice(address asset) public override view returns (uint) {
//        return _getLatestPriceInUSD(asset);
//    }
//
//    function getPrices(address[] calldata assets) external override view returns (uint[] memory) {
//        uint[] memory prices = new uint[](assets.length);
//        for (uint i = 0; i < assets.length; ++i) {
//            prices[i] = _getLatestPriceInUSD(assets[i]);
//        }
//        return prices;
//    }
//
//    function _getLatestPriceInUSD(address asset) internal view returns (uint) {
//        require(asset != address(0), 'ChainlinkIntegration._getLatestPriceInUSD: asset must be valid');
//        (uint8 target, address feeds) = IHonestConfiguration(_honestConfiguration).basketAssetPriceIntegration(asset);
//        if (target == uint8(IAssetPriceIntegration.FeedsTarget.USD)) {
//            return _getLatestPrice(feeds);
//        } else if (target == uint8(IAssetPriceIntegration.FeedsTarget.ETH)) {
//            uint price = _getLatestPrice(feeds);
//            return price.mul(_getLatestPrice(_ethUsdFeeds)).div(1e18);
//        } else {
//            return 0;
//        }
//    }
//
//    function _getLatestPrice(address feed) internal view returns (uint) {
//        (,int256 price,,uint updatedAt,) = AggregatorV3Interface(feed).latestRoundData();
//        require(updatedAt > 0, 'ChainlinkIntegration._getLatestPrice: round not complete');
//        require(price > 0, 'ChainlinkIntegration._getLatestPrice: unusual price from feeds');
//
//        uint8 decimals = AggregatorV3Interface(feed).decimals();
//        if (decimals == 18) {
//            return uint(price);
//        } else if (decimals > 18) {
//            return uint(price).div(uint(10) ** uint(decimals - 18));
//        } else {
//            return uint(price).mul(uint(10) ** uint(18 - decimals));
//        }
//    }
//}