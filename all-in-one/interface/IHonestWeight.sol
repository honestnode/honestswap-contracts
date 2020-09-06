pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

interface IHonestWeight {

    function getTotalWeight() external view
    returns (uint256 weight);

    function getWeight(address _saver) external view
    returns (uint256 weight);

    function getWeights(address[] calldata _savers) external view
    returns (uint256[] memory weights);

    function addWeight(address _saver, uint256 _weight) external
    returns (uint256 newWeight);

    function addWeights(address[] calldata _savers, uint256[] calldata _weights) external
    returns (uint256[] memory newWeights);

    function minusWeight(address _saver, uint256 _weight) external
    returns (uint256 newWeight);

    function minusWeights(address[] calldata _savers, uint256[] calldata _weights) external
    returns (uint256[] memory newWeights);

    function clearWeight(address _saver) external
    returns (bool result);

    //    function clearWeights(address[] _savers) external
    //    returns (bool[] results);
}
