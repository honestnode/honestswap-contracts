pragma solidity ^0.5.0;

import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {WhitelistedRole} from '@openzeppelin/contracts/access/roles/WhitelistedRole.sol';
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.5/interfaces/AggregatorV3Interface.sol";

import {IAssetPriceIntegration} from "./IAssetPriceIntegration.sol";

contract ChainlinkIntegration is IAssetPriceIntegration, WhitelistedRole {

    using Address for address;
    using SafeMath for uint256;

    address constant private _ETH_ASSET = address(0);

    mapping(address => address) private _usdFeeds;
    mapping(address => address) private _ethFeeds;

    function initialize(FeedsTarget[] calldata _types, address[] calldata _assets, address[] calldata _feedsContracts)
    external onlyWhitelistAdmin {
        require(_types.length == _assets.length, 'mismatch assets and feeds contracts length');
        require(_types.length == _feedsContracts.length, 'mismatch assets and feeds contracts length');

        for(uint256 i = 0; i < _types.length; ++i) {
            register(_types[i], _assets[i], _feedsContracts[i]);
        }
    }

    function register(FeedsTarget _type, address _asset, address _feedsContract)
    public onlyWhitelistAdmin {
        if (_type == FeedsTarget.USD) {
            _usdFeeds[_asset] = _feedsContract;
        } else if (_type == FeedsTarget.ETH) {
            _ethFeeds[_asset] = _feedsContract;
        }
    }

    function deregister(FeedsTarget _type, address _asset)
    public onlyWhitelistAdmin {
        if (_type == FeedsTarget.USD) {
            delete _usdFeeds[_asset];
        } else if (_type == FeedsTarget.ETH) {
            delete _ethFeeds[_asset];
        }
    }

    function getPrice(address _asset) public view returns (uint256) {
        return _getLatestPriceInUSD(_asset);
    }

    function getPrices(address[] calldata _assets) external view returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](_assets.length);
        for(uint256 i = 0; i < _assets.length; ++i) {
            prices[i] = _getLatestPriceInUSD(_assets[i]);
        }
        return prices;
    }

    function _getLatestPriceInUSD(address _asset) internal view returns (uint256) {
        address feed = _usdFeeds[_asset];
        if (feed != address(0)) {
            return _getLatestPrice(feed);
        }
        feed = _ethFeeds[_asset];
        require(feed != address(0), 'available price feeds contract not found');
        require(_usdFeeds[_ETH_ASSET] != address(0), 'available eth/usd price feeds contract not found');
        uint256 price = _getLatestPrice(feed);
        return price.mul(_getLatestPrice(_usdFeeds[_ETH_ASSET])).div(1e18);
    }

    function _getLatestPrice(address _feed) internal view returns (uint256) {
        (uint80 roundId,
        int256 price,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
        ) = AggregatorV3Interface(_feed).latestRoundData();
        require(updatedAt > 0, 'round not complete');
        require(price > 0, 'unusual price from feeds');

        uint8 decimals = AggregatorV3Interface(_feed).decimals();
        if (decimals == 18) {
            return uint256(price);
        } else if (decimals > 18) {
            return uint256(price).div(uint256(10) ** uint256(decimals - 18));
        } else {
            return uint256(price).mul(uint256(10) ** uint256(18 - decimals));
        }
    }
}