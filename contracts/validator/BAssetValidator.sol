pragma solidity ^0.5.0;

import {IBAssetValidator} from "../validator/IBAssetValidator.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

contract BAssetValidator is IBAssetValidator {
    using SafeMath for uint256;

    /** @dev Basket balance value of each bAsset */
    function validateMint(address _bAsset, uint8 _bAssetStatus, uint256 _bAssetQuantity)
    external
    pure
    returns (bool, string memory){
        if (_bAssetStatus != uint(BAssetStatus.Normal)) {
            return (false, "bAsset status is not valid");
        }
        return (true, "");
    }

    function validateMintMulti(address[] calldata _bAssets, uint8[] calldata _bAssetStatus, uint256[] calldata _bAssetQuantities)
    external
    pure
    returns (bool, string memory){
        for (uint256 i = 0; i < _bAssetStatus.length; i++) {
            if (_bAssetStatus[i] != uint(BAssetStatus.Normal)) {
                return (false, "bAsset status is not valid");
            }
        }
        return (true, "");
    }

    function validateRedeem(address[] calldata _bAssets, uint8[] calldata _bAssetStatus, uint256[] calldata _bAssetQuantities)
    external
    pure
    returns (bool, string memory){
        for (uint256 i = 0; i < _bAssetStatus.length; i++) {
            if (_bAssetStatus[i] != uint(BAssetStatus.Normal)) {
                return (false, "bAsset status is not valid");
            }
        }
        return (true, "");
    }

    function validateSwap(address _inputBAsset, uint8 _inputBAssetStatus, address _outputBAsset, uint8 _outputBAssetStatus, uint256 _quantity)
    external
    pure
    returns (bool, string memory){
        if (_inputBAssetStatus != uint(BAssetStatus.Normal)) {
            return (false, "Input bAsset status is not valid");
        }
        if (_outputBAssetStatus != uint(BAssetStatus.Normal)) {
            return (false, "Output bAsset status is not valid");
        }
        return (true, "");
    }

    function filterValidBAsset(address[] calldata _bAssets, uint8[] calldata _bAssetStatus)
    external
    pure
    returns (address[] memory validBAssets){
        validBAssets = new address[](_bAssets.length);
        uint256 index = 0;
        for (uint256 i = 0; i < _bAssetStatus.length; i++) {
            if (_bAssetStatus[i] == uint(BAssetStatus.Normal)) {
                validBAssets[index] = _bAssets[i];
                index = index.add(1);
            }
        }
        return validBAssets;
    }
}
