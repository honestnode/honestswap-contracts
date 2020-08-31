pragma solidity 0.5.16;

interface IHonestWeight {

    function getWeight(address _saver) external view
    returns (uint256 weight);

    function getWeights(address[] _savers) external view
    returns (uint256[] weights);

    function addWeight(address _saver, uint256 _weight) external
    returns (uint256 newWeight);

    function addWeights(address[] _savers, uint256[] _weights) external
    returns (uint256[] newWeights);

    function minusWeight(address _saver, uint256 _weight) external
    returns (uint256 newWeight);

    function minusWeights(address[] _savers, uint256[] _weights) external
    returns (uint256[] newWeights);

    function clearWeight(address _saver) external
    returns (bool result);

    //    function clearWeights(address[] _savers) external
    //    returns (bool[] results);
}
