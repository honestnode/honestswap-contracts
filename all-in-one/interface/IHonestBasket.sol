pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;
import {HassetStructs} from "./HassetStructs.sol";

contract  IHonestBasket is HassetStructs {

    /** @dev Setters for mAsset to update balances */
    function increasePoolBalance(
        uint8 _bAssetIndex,
        uint256 _increaseAmount) external;
    function increasePoolBalances(
        uint8[] calldata _bAssetIndices,
        uint256[] calldata _increaseAmount) external;
    function decreasePoolBalance(
        uint8 _bAssetIndex,
        uint256 _decreaseAmount) external;
    function decreasePoolBalances(
        uint8[] calldata _bAssetIndices,
        uint256[] calldata _decreaseAmount) external;

    function increaseSavingBalance(
        uint8 _bAssetIndex,
        uint256 _increaseAmount) external;
    function increaseSavingBalances(
        uint8[] calldata _bAssetIndices,
        uint256[] calldata _increaseAmount) external;
    function decreaseSavingBalance(
        uint8 _bAssetIndex,
        uint256 _decreaseAmount) external;
    function decreaseSavingBalances(
        uint8[] calldata _bAssetIndices,
        uint256[] calldata _decreaseAmount) external;

    function collectInterest() external
    returns (uint256 interestCollected, uint256[] memory gains);

    /** @dev Setters for Gov to update Basket composition */
    function addBasset(
        address _basset,
        address _integration,
        bool _isTransferFeeCharged) external returns (uint8 index);
    function setTransferFeesFlag(address _bAsset, bool _flag) external;

    /** @dev Getters to retrieve Basket information */
    function getBasket() external view returns (Basket memory b);

    function prepareForgeBasset(address _token) external
    returns (bool isValid, BassetDetails memory bInfo);

    function prepareSwapBassets(address _input, address _output, bool _isMint) external view
    returns (bool, string memory, BassetDetails memory, BassetDetails memory);

    function prepareForgeBassets(address[] calldata _bAssets) external
    returns (ForgePropsMulti memory props);

    function prepareRedeemMulti() external view
    returns (RedeemPropsMulti memory props);

    function getBasset(address _token) external view
    returns (Basset memory bAsset);

    function getBassets() external view
    returns (Basset[] memory bAssets, uint256 len);

}
