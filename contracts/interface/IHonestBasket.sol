pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import {HassetStructs} from "./HassetStructs.sol";

contract IHonestBasket is HassetStructs {

    /** @dev Setters for mAsset to update balances */
    function increasePoolBalance(uint8 _bAssetIndex, uint256 _increaseAmount) external;

    function increasePoolBalances(uint8[] calldata _bAssetIndices, uint256[] calldata _increaseAmounts) external;

    function decreasePoolBalance(uint8 _bAssetIndex, uint256 _decreaseAmount) external;

    function decreasePoolBalances(uint8[] calldata _bAssetIndices, uint256[] calldata _decreaseAmounts) external;

    function increaseSavingBalance(uint8 _bAssetIndex, uint256 _increaseAmount) external;

    function increaseSavingBalances(uint8[] calldata _bAssetIndices, uint256[] calldata _increaseAmounts) external;

    function decreaseSavingBalance(uint8 _bAssetIndex, uint256 _decreaseAmount) external;

    function decreaseSavingBalances(uint8[] calldata _bAssetIndices, uint256[] calldata _decreaseAmounts) external;

    function increaseFeeBalance(uint8 _bAssetIndex, uint256 _increaseAmount) external;

    function increaseFeeBalances(uint8[] calldata _bAssetIndices, uint256[] calldata _increaseAmounts) external;

    function decreaseFeeBalance(uint8 _bAssetIndex, uint256 _decreaseAmount) external;

    function decreaseFeeBalances(uint8[] calldata _bAssetIndices, uint256[] calldata _decreaseAmounts) external;

    function increasePlatformBalance(uint8 _bAssetIndex, uint256 _increaseAmount) external;

    function increasePlatformBalances(uint8[] calldata _bAssetIndices, uint256[] calldata _increaseAmounts) external;

    function decreasePlatformBalance(uint8 _bAssetIndex, uint256 _decreaseAmount) external;

    function decreasePlatformBalances(uint8[] calldata _bAssetIndices, uint256[] calldata _decreaseAmounts) external;

    // update balance after deposit
    function mintForBalance(uint8[] calldata _bAssetIndices, uint256[] calldata _amounts) external;
    function withdrawForBalance(uint8[] calldata _bAssetIndices, uint256[] calldata _amounts) external;

    function depositForBalance(uint8[] calldata _bAssetIndices, uint256[] calldata _amounts) external;
    function redeemForBalance(uint8[] calldata _bAssetIndices, uint256[] calldata _amounts) external;

    function swapForBalance(uint8[] calldata _bAssetIndices, uint256[] calldata _amounts) external;
    //    function collectInterest() external
    //    returns (uint256 interestCollected, uint256[] memory gains);

    /** @dev Setters for Gov to update Basket composition */
    function addBasset(address _basset, address _integration, bool _isTransferFeeCharged) external returns (uint8 index);

    function setTransferFeesFlag(address _bAsset, bool _flag) external;

    /** @dev Getters to retrieve Basket information */
    function getBasket() external view returns (Basket memory b);

    function prepareForgeBasset(address _token) external
    returns (bool isValid, BassetDetails memory bInfo);

    function prepareSwapBassets(address _input, address _output, bool _isMint) external
    returns (bool, string memory, BassetDetails memory, BassetDetails memory);

    function prepareForgeBassets(address[] calldata _bAssets) external
    returns (BassetPropsMulti memory props);

    function preparePropsMulti() external returns (BassetPropsMulti memory props);

    function getBasset(address _token) external returns (Basset memory bAsset);

//    function getBassets() external view returns (Basset[] memory bAssets, uint256 len);

}
