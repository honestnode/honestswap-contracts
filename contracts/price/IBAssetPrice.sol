pragma solidity ^0.5.0;
//pragma experimental ABIEncoderV2;

/**
 * @title Price interface to integrate with tamper-proof like ChainLink etc.
 */
interface IBAssetPrice {

    /** @dev query bAsset price */
    function getBassetPrice(address _bAsset) external view returns (uint256 price, uint256 decimals);
    /** @dev query bAsset prices */
    function getBassetsPrice(address[] calldata _bAssets) external view returns (uint256[] memory prices, uint256[] memory decimals);

}
