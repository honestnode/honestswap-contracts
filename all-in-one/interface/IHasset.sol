pragma solidity 0.5.16;

// Libs
import {HassetStructs} from "./HassetStructs.sol";

contract IHasset is HassetStructs {

    /** @dev Minting */
    function mint(address _basset, uint256 _bassetQuantity)
    external returns (uint256 hAssetMinted);

    function mintTo(address _basset, uint256 _bassetQuantity, address _recipient)
    external returns (uint256 hAssetMinted);

    function mintMulti(address[] calldata _bAssets, uint256[] calldata _bassetQuantity, address _recipient)
    external returns (uint256 hAssetMinted);

    /** @dev Redeeming */
    function redeem(address _basset, uint256 _bassetQuantity)
    external returns (uint256 hAssetRedeemed);

    function redeemTo(address _basset, uint256 _bassetQuantity, address _recipient)
    external returns (uint256 hAssetRedeemed);

    function redeemMulti(address[] calldata _bAssets, uint256[] calldata _bassetQuantities, address _recipient)
    external returns (uint256 hAssetRedeemed);

    function redeemHasset(uint256 _mAssetQuantity, address _recipient) external;

    /** @dev Setters for Gov to set system params */
    function setRedemptionFee(uint256 _redemptionFee) external;

    /** @dev Getters */
//    function getBasketManager() external view returns (address);

}
