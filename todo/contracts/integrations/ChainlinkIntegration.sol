pragma solidity ^0.6.0;

import {AccessControlUpgradeSafe} from '@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol';
import {AccessControlUpgradeSafe} from '@openzeppelin/contracts-ethereum-package/contracts/access/AccessControl.sol';
import {SafeMath} from '@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol';
import {WhitelistedRole} from '@openzeppelin/contracts-ethereum-package/contracts/access/roles/WhitelistedRole.sol';
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.5/interfaces/AggregatorV3Interface.sol";

import {IAssetPriceIntegration} from "./IAssetPriceIntegration.sol";

contract ChainlinkIntegration is Initializable, IAssetPriceIntegration, AccessControlUpgradeSafe {

    using SafeMath for uint;

    address constant private _ETH_ASSET = address(0);

    mapping(address => address) private _usdFeeds;
    mapping(address => address) private _ethFeeds;

    function initialize(FeedsTarget[] calldata _types, address[] calldata _assets, address[] calldata _feedsContracts)
    public initializer {
        require(_types.length == _assets.length, 'mismatch assets and feeds contracts length');
        require(_types.length == _feedsContracts.length, 'mismatch assets and feeds contracts length');

        for(uint i = 0; i < _types.length; ++i) {
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

    function getPrice(address _asset) public view returns (uint) {
        return _getLatestPriceInUSD(_asset);
    }

    function getPrices(address[] calldata _assets) external view returns (uint[] memory) {
        uint[] memory prices = new uint[](_assets.length);
        for(uint i = 0; i < _assets.length; ++i) {
            prices[i] = _getLatestPriceInUSD(_assets[i]);
        }
        return prices;
    }

    function _getLatestPriceInUSD(address _asset) internal view returns (uint) {
        address feed = _usdFeeds[_asset];
        if (feed != address(0)) {
            return _getLatestPrice(feed);
        }
        feed = _ethFeeds[_asset];
        require(feed != address(0), 'available price feeds contract not found');
        require(_usdFeeds[_ETH_ASSET] != address(0), 'available eth/usd price feeds contract not found');
        uint price = _getLatestPrice(feed);
        return price.mul(_getLatestPrice(_usdFeeds[_ETH_ASSET])).div(1e18);
    }

    function _getLatestPrice(address _feed) internal view returns (uint) {
        (uint80 roundId,
        int256 price,
        uint startedAt,
        uint updatedAt,
        uint80 answeredInRound
        ) = AggregatorV3Interface(_feed).latestRoundData();
        require(updatedAt > 0, 'round not complete');
        require(price > 0, 'unusual price from feeds');

        uint8 decimals = AggregatorV3Interface(_feed).decimals();
        if (decimals == 18) {
            return uint(price);
        } else if (decimals > 18) {
            return uint(price).div(uint(10) ** uint(decimals - 18));
        } else {
            return uint(price).mul(uint(10) ** uint(18 - decimals));
        }
    }
}