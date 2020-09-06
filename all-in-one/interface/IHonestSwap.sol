pragma solidity 0.5.16;

/**
 * @title   IHonestSwap
 * @author  HonestSwap. Ltd.
 */
interface IHonestSwap {

    function swap(address _inputBAsset, address _outputBAsset, uint256 _quantity, address _recipient)
    external returns (bool, string memory, uint256 outputQuantity);

    function checkSwap(address _inputBAsset, address _outputBAsset, uint256 _quantity, address _recipient)
    external returns (bool, string memory, uint256 outputQuantity);
}
