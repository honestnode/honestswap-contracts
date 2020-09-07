pragma solidity 0.5.16;

// Libs
import {HassetStructs} from "./HassetStructs.sol";

contract IHasset is HassetStructs {

    /** @dev Minting */
    function mint(address _bAsset, uint256 _bAssetQuantity)
    external returns (uint256 hAssetMinted);

    function mintTo(address _bAsset, uint256 _bAssetQuantity, address _recipient)
    external returns (uint256 hAssetMinted);

    function mintMulti(address[] calldata _bAssets, uint256[] calldata _bAssetQuantity, address _recipient)
    external returns (uint256 hAssetMinted);

    /** @dev Redeeming */
    function redeem(address _bAsset, uint256 _bAssetQuantity)
    external returns (uint256 hAssetRedeemed);

    function redeemTo(address _bAsset, uint256 _bAssetQuantity, address _recipient)
    external returns (uint256 hAssetRedeemed);

    function redeemMulti(address[] calldata _bAssets, uint256[] calldata _bAssetQuantities, address _recipient, bool _inProportion)
    external returns (uint256 hAssetRedeemed);

//    function redeemHasset(uint256 _hAssetQuantity, address _recipient) external;
    /** @dev Setters for Gov to set system params */
    function setRedemptionFee(uint256 _redemptionFee) external;

    /** @dev Getters */
    //    function getBasketManager() external view returns (address);

}
