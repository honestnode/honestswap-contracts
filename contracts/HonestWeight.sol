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
    mapping(address => uint256) private saverBonusWeights;

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

        uint256 savingWeight = saverWeights[msg.sender];
        uint256 bonusWeight = saverWeights[msg.sender];
        weight = savingWeight.add(bonusWeight);
    }

    function getWeights(address[] calldata _savers) external view
    returns (uint256[] memory weights){
        uint256 len = _savers.length;
        require(len > 0, "Input array is empty");

        weights = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            address saver = _savers[i];
            uint256 savingWeight = saverWeights[saver];
            uint256 bonusWeight = saverWeights[saver];

            weights[i] = savingWeight.add(bonusWeight);
        }

        return weights;
    }

    /**
     * @dev Add saver's weight
     * @param _saver    saver address
     * @param _savingWeight   saving weight to be added
     * @param _bonusWeight   bonus weight to be added
     */
    function addWeight(address _saver, uint256 _savingWeight, uint256 _bonusWeight) external nonReentrant
    onlyWeightManager
    returns (uint256 newWeight){
        require(_saver != address(0), "Must be a valid saver");
        require(_savingWeight > 0 || _bonusWeight > 0, "Weight must not be 0");

        uint256 oldWeight = 0;
        newWeight = 0;
        // add weight to saver
        if (_savingWeight > 0) {
            uint256 oldSavingWeight = saverWeights[_saver];
            oldWeight = oldWeight.add(oldSavingWeight);
            uint256 newSavingWeight = oldSavingWeight.add(_savingWeight);
            newWeight = newWeight.add(newSavingWeight);
            saverWeights[_saver] = newSavingWeight;
            // update total weight
            totalWeight = totalWeight.add(_savingWeight);
        }
        if (_bonusWeight > 0) {
            uint256 oldBonusWeight = saverBonusWeights[_saver];
            oldWeight = oldWeight.add(oldBonusWeight);
            uint256 newBonusWeight = oldBonusWeight.add(_bonusWeight);
            newWeight = newWeight.add(newBonusWeight);
            saverBonusWeights[_saver] = newBonusWeight;
            totalWeight = totalWeight.add(_bonusWeight);
        }
        emit WeightUpdated(_saver, newWeight, oldWeight);
    }

    function addWeights(address[] calldata _savers, uint256[] calldata _savingWeights, uint256[] calldata _bonusWeights) external
    nonReentrant
    onlyWeightManager
    returns (uint256[] memory newWeights){
        uint256 len = _savers.length;
        uint256 len1 = _savingWeights.length;
        uint256 len2 = _bonusWeights.length;
        require((len > 0 && len == len1) || (len > 0 && len == len2), "Input array mismatch");

        newWeights = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            address saver = _savers[i];
            uint256 savingWeightToAdd = _savingWeights[i];
            uint256 bonusWeightToAdd = _bonusWeights[i];
            uint256 oldWeight = 0;
            uint256 newWeight = 0;
            if (savingWeightToAdd > 0 && saver != address(0)) {
                // add weight to saver
                uint256 oldSavingWeight = saverWeights[saver];
                oldWeight = oldWeight.add(oldSavingWeight);
                uint256 newSavingWeight = oldSavingWeight.add(savingWeightToAdd);
                saverWeights[saver] = newSavingWeight;
                newWeight = newWeight.add(newSavingWeight);
                // update total weight
                totalWeight = totalWeight.add(savingWeightToAdd);
            }
            if (bonusWeightToAdd > 0 && saver != address(0)) {
                // add weight to saver
                uint256 oldBonusWeight = saverBonusWeights[saver];
                oldWeight = oldWeight.add(oldBonusWeight);
                uint256 newBonusWeight = oldBonusWeight.add(bonusWeightToAdd);
                saverBonusWeights[saver] = newBonusWeight;
                newWeight = newWeight.add(newBonusWeight);

                // update total weight
                totalWeight = totalWeight.add(bonusWeightToAdd);
            }
            newWeights[i] = newWeight;
            emit WeightUpdated(saver, newWeight, oldWeight);
        }
    }

    function minusWeight(address _saver, uint256 _savingWeight, uint256 _bonusWeight) external
    nonReentrant
    onlyWeightManager
    returns (uint256 newWeight){
        require(_saver != address(0), "Must be a valid saver");
        require(_savingWeight > 0 || _bonusWeight > 0, "Weight must not be 0");

        newWeight = 0;
        // add weight to saver
        uint256 oldSavingWeight = saverWeights[_saver];
        uint256 oldBonusWeight = saverBonusWeights[_saver];
        uint256 oldWeight = oldSavingWeight.add(oldBonusWeight);
        if (_savingWeight > 0) {
            require(oldSavingWeight > 0, "Old saving weight must not be 0");
            require(oldSavingWeight >= _savingWeight, "Old saving weight not enough to minus");
            uint256 newSavingWeight = oldSavingWeight.sub(_savingWeight);
            newWeight = newWeight.add(newSavingWeight);
            saverWeights[_saver] = newSavingWeight;
            // update total weight
            totalWeight = totalWeight.sub(_savingWeight);
        }
        if (_bonusWeight > 0) {
            require(oldBonusWeight > 0, "Old bonus weight must not be 0");
            require(oldBonusWeight >= _bonusWeight, "Old bonus weight not enough to minus");
            uint256 newBonusWeight = oldBonusWeight.sub(_bonusWeight);
            newWeight = newWeight.add(newBonusWeight);
            saverBonusWeights[_saver] = newBonusWeight;
            // update total weight
            totalWeight = totalWeight.sub(_bonusWeight);
        }
        emit WeightUpdated(_saver, newWeight, oldWeight);
    }

    function minusWeights(address[] calldata _savers, uint256[] calldata _savingWeights, uint256[] calldata _bonusWeights)
    external
    nonReentrant
    onlyWeightManager
    returns (uint256[] memory newWeights){
        uint256 len = _savers.length;
        uint256 len1 = _savingWeights.length;
        uint256 len2 = _bonusWeights.length;
        require((len > 0 && len == len1) || (len > 0 && len == len2), "Input array mismatch");

        newWeights = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            address saver = _savers[i];
            uint256 savingWeightToSub = _savingWeights[i];
            uint256 bonusWeightToSub = _bonusWeights[i];
            uint256 oldWeight = 0;
            uint256 newWeight = 0;
            if (savingWeightToSub > 0 && saver != address(0)) {
                // add weight to saver
                uint256 oldSavingWeight = saverWeights[saver];
                require(oldSavingWeight > savingWeightToSub, "Not enough saving weight to sub");
                oldWeight = oldWeight.add(oldSavingWeight);
                uint256 newSavingWeight = oldSavingWeight.sub(savingWeightToSub);
                saverWeights[saver] = newSavingWeight;
                newWeight = newWeight.add(newSavingWeight);
                // update total weight
                require(totalWeight > savingWeightToSub, "Not enough total weight to sub");
                totalWeight = totalWeight.sub(savingWeightToSub);
            }
            if (bonusWeightToSub > 0 && saver != address(0)) {
                // add weight to saver
                uint256 oldBonusWeight = saverBonusWeights[saver];
                require(oldBonusWeight > bonusWeightToSub, "Not enough bonus weight to sub");
                oldWeight = oldWeight.add(oldBonusWeight);
                uint256 newBonusWeight = oldBonusWeight.sub(bonusWeightToSub);
                saverBonusWeights[saver] = newBonusWeight;
                newWeight = newWeight.add(newBonusWeight);

                // update total weight
                require(totalWeight > bonusWeightToSub, "Not enough total weight to sub");
                totalWeight = totalWeight.sub(bonusWeightToSub);
            }
            newWeights[i] = newWeight;
            emit WeightUpdated(saver, newWeight, oldWeight);
        }
    }

    function clearWeight(address _saver) external nonReentrant
    onlyWeightManager
    returns (bool result){
        require(_saver != address(0), "Must be a valid saver");

        uint256 oldSavingWeight = saverWeights[_saver];
        uint256 oldBonusWeight = saverBonusWeights[_saver];
        uint256 oldWeight = oldSavingWeight.add(oldBonusWeight);
        if (oldSavingWeight > 0) {
            saverWeights[_saver] = 0;
            require(totalWeight > oldSavingWeight, "Not enough total weight to sub");
            totalWeight = totalWeight.sub(oldSavingWeight);
        }
        if (oldBonusWeight > 0) {
            saverBonusWeights[_saver] = 0;
            require(totalWeight > oldBonusWeight, "Not enough total weight to sub");
            totalWeight = totalWeight.sub(oldBonusWeight);
        }
        emit WeightUpdated(_saver, 0, oldWeight);
        return true;
    }

    //    function clearWeights(address[] _savers) external nonReentrant
    //    returns (bool[] results){
    //
    //    }

}
