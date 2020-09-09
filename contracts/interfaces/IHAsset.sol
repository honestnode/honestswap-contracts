pragma solidity ^0.5.0;

interface IHAsset {

    /** @dev Minting */
    function mint(address _bAsset, uint256 _bAssetQuantity) external returns (uint256 hAssetMinted);

    function mintTo(address _bAsset, uint256 _bAssetQuantity, address _recipient) external returns (uint256 hAssetMinted);

    function mintMulti(address[] calldata _bAssets, uint256[] calldata _bAssetQuantity, address _recipient)
    external returns (uint256 hAssetMinted);

    /** @dev Redeeming */
    function redeem(address _bAsset, uint256 _bAssetQuantity) external returns (uint256 hAssetRedeemed);

    function redeemTo(address _bAsset, uint256 _bAssetQuantity, address _recipient) external returns (uint256 hAssetRedeemed);

    function redeemMulti(address[] calldata _bAssets, uint256[] calldata _bAssetQuantities, address _recipient, bool _inProportion)
    external returns (uint256 hAssetRedeemed);
}