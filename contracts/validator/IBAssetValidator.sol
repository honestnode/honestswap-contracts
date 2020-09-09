pragma solidity ^0.5.0;

interface IBAssetValidator {

    enum BAssetStatus {
        Normal,
        Blacklisted,
        Liquidating,
        Liquidated,
        Failed
    }

    /** @dev Basket balance value of each bAsset */
    function validateMint(address _bAsset, uint8 _bAssetStatus, uint256 _bAssetQuantity) external pure returns (bool, string memory);

    function validateMintMulti(address[] calldata _bAssets, uint8[] calldata _bAssetStatus, uint256[] calldata _bAssetQuantities)
    external pure returns (bool, string memory);

    function validateRedeem(address[] calldata _bAssets, uint8[] calldata _bAssetStatus, uint256[] calldata _bAssetQuantities)
    external pure returns (bool, string memory);

    function validateSwap(address _inputBAsset, uint8 _inputBAssetStatus, address _outputBAsset, uint8 _outputBAssetStatus, uint256 _quantity)
    external pure returns (bool, string memory);

}
