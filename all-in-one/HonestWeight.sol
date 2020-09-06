pragma solidity 0.5.16;

import {IHonestWeight} from "./interface/IHonestWeight.sol";
import {Module} from "./common/Module.sol";
import {InitializableModule} from "./common/InitializableModule.sol";
import {InitializableReentrancyGuard} from "./common/InitializableReentrancyGuard.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title   HonestWeight
 * @author  HonestSwap. Ltd.
 * @notice  HonestWeight save the weights of all savers
 * @dev     VERSION: 1.0
 */
contract HonestWeight is
IHonestWeight, Module, InitializableModule, InitializableReentrancyGuard {

    using SafeMath for uint256;

    // Core events for weight change
    event WeightUpdated(address indexed saver, uint256 newWeight, uint256 oldWeight);

    // Total weight
    uint256 private totalWeight;
    // Amount of weight for each saver
    mapping(address => uint256) private saverWeights;

    modifier onlyWeightManager() {
        require(_savingsManager() == msg.sender, "Must be weight manager");
        _;
    }

    /**
     * @dev Query total weight
     * @param _saver   saver address
     */
    function getTotalWeight() external view
    returns (uint256 weight){
        return totalWeight;
    }

    /**
     * @dev Query saver's weight
     * @param _saver   saver address
     */
    function getWeight(address _saver) external view
    returns (uint256 weight){
        require(_saver != address(0), "Must be a valid saver");

        uint256 weight = saverWeights[msg.sender];
        return weight;
    }

    function getWeights(address[] _savers) external view
    returns (uint256[] weights){
        uint256 len = _savers.length;
        require(len > 0, "Input array is empty");

        uint256[] weights = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            address saver = _savers[i];
            uint256 weight = saverWeights[_saver];
            weights[i] = weight;
        }

        return weights;
    }

    /**
     * @dev Add saver's weight
     * @param _saver    saver address
     * @param _weight   weight to be added
     */
    function addWeight(address _saver, uint256 _weight) external nonReentrant
    onlySavingsManager
    returns (uint256 newWeight){
        require(_saver != address(0), "Must be a valid saver");
        require(_weight > 0, "Weight must not be 0");

        // add weight to saver
        uint256 oldWeight = saverWeights[msg.sender];
        uint256 newWeight = oldWeight.add(_weight);
        saverWeights[msg.sender] = newWeight;
        // update total weight
        totalWeight = totalWeight.add(_weight);

        emit WeightUpdated(_saver, newWeight, oldWeight);

        return newWeight;
    }

    function addWeights(address[] _savers, uint256[] _weights) external
    nonReentrant
    onlySavingsManager
    returns (uint256[] newWeights){
        uint256 len = _weights.length;
        require(len > 0 && len == _savers.length, "Input array mismatch");

        uint256[] weights = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            address saver = _savers[i];
            uint256 weightToAdd = _weights[i];
            if (weightToAdd > 0 && saver != address(0)) {
                // add weight to saver
                uint256 oldWeight = saverWeights[saver];
                uint256 newWeight = oldWeight.add(weightToAdd);
                saverWeights[saver] = newWeight;
                // update total weight
                totalWeight = totalWeight.add(weightToAdd);

                weights[i] = newWeight;

                emit WeightUpdated(saver, newWeight, oldWeight);
            }
        }

        return weights;
    }

    function minusWeight(address _saver, uint256 _weight) external
    nonReentrant
    onlySavingsManager
    returns (uint256 newWeight){
        require(_saver != address(0), "Must be a valid saver");
        require(_weight > 0, "Weight must not be 0");

        // add weight to saver
        uint256 oldWeight = saverWeights[msg.sender];
        require(oldWeight > 0, "Old weight must not be 0");
        require(oldWeight >= _weight, "Old weight not enough to minus");
        uint256 newWeight = oldWeight.sub(_weight);
        saverWeights[msg.sender] = newWeight;
        // update total weight
        totalWeight = totalWeight.sub(_weight);

        emit WeightUpdated(_saver, newWeight, oldWeight);

        return newWeight;
    }

    function minusWeights(address[] _savers, uint256[] _weights) external nonReentrant
    onlySavingsManager
    returns (uint256[] newWeights){
        uint256 len = _weights.length;
        require(len > 0 && len == _savers.length, "Input array mismatch");

        uint256[] weights = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            address saver = _savers[i];
            uint256 weightToSub = _weights[i];
            if (weightToSub > 0 && saver != address(0)) {
                // add weight to saver
                uint256 oldWeight = saverWeights[saver];
                if (oldWeight > 0 && oldWeight >= weightToSub) {
                    uint256 newWeight = oldWeight.sub(weightToSub);
                    saverWeights[saver] = newWeight;
                    // update total weight
                    totalWeight = totalWeight.sub(weightToSub);
                    weights[i] = newWeight;

                    emit WeightUpdated(saver, newWeight, oldWeight);
                }
            }
        }
        return weights;
    }

    function clearWeight(address _saver) external nonReentrant
    onlySavingsManager
    returns (bool result){
        require(_saver != address(0), "Must be a valid saver");

        uint256 oldWeight = saverWeights[_saver];
        if (oldWeight > 0) {
            saverWeights[_saver] = 0;
            totalWeight = totalWeight.sub(oldWeight);
        }
        return true;
    }

    //    function clearWeights(address[] _savers) external nonReentrant
    //    returns (bool[] results){
    //
    //    }

}
