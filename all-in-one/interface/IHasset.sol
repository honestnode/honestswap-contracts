pragma solidity 0.5.16;

// Libs
import {Initializable} from "@openzeppelin/upgrades/contracts/Initializable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {HassetStructs} from "./HassetStructs.sol";

contract IHasset is HassetStructs {

    /** @dev Calc interest */
    function collectInterest() external returns (uint256 hAssetMinted, uint256 newTotalSupply);

    /** @dev Minting */
    function mint(address _basset, uint256 _bassetQuantity)
    external returns (uint256 hAssetMinted);

    function mintTo(address _basset, uint256 _bassetQuantity, address _recipient)
    external returns (uint256 hAssetMinted);

    function mintMulti(address[] calldata _bAssets, uint256[] calldata _bassetQuantity, address _recipient)
    external returns (uint256 hAssetMinted);

    /** @dev Swapping */
    function swap(address _input, address _output, uint256 _quantity, address _recipient)
    external returns (uint256 output);

    function getSwapOutput(address _input, address _output, uint256 _quantity)
    external view returns (bool, string memory, uint256 output);

    /** @dev Redeeming */
    function redeem(address _basset, uint256 _bassetQuantity)
    external returns (uint256 hAssetRedeemed);

    function redeemTo(address _basset, uint256 _bassetQuantity, address _recipient)
    external returns (uint256 hAssetRedeemed);

    function redeemMulti(address[] calldata _bAssets, uint256[] calldata _bassetQuantities, address _recipient)
    external returns (uint256 hAssetRedeemed);

    function redeemMasset(uint256 _mAssetQuantity, address _recipient) external;

    /** @dev Setters for the Manager or Gov to update module info */
    function upgradeForgeValidator(address _newForgeValidator) external;

    /** @dev Setters for Gov to set system params */
    function setSwapFee(uint256 _swapFee) external;

    /** @dev Getters */
    function getBasketManager() external view returns (address);

}
