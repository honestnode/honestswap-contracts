pragma solidity ^0.6.0;

import {Initializable} from '@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol';
import {AccessControlUpgradeSafe} from '@openzeppelin/contracts-ethereum-package/contracts/access/AccessControl.sol';

abstract contract AbstractHonestContract is Initializable, AccessControlUpgradeSafe {

    bytes32 public constant ASSET = keccak256("HONEST_ASSET");
    bytes32 public constant ASSET_MANAGER = keccak256("HONEST_ASSET_MANAGER");
    bytes32 public constant VAULT = keccak256("HONEST_VAULT");
    bytes32 public constant SAVINGS = keccak256("HONEST_SAVINGS");
    bytes32 public constant GOVERNOR = keccak256("HONEST_GOVERNOR");

    modifier onlyAssetManager() {
        require(hasRole(ASSET_MANAGER, msg.sender), "AccessControl: caller is not the AssetManager contract");
    }

    modifier onlyVault() {
        require(hasRole(VAULT, msg.sender), "AccessControl: caller is not the Vault contract");
    }

    modifier onlySavings() {
        require(hasRole(SAVINGS, msg.sender), "AccessControl: caller is not the Savings contract");
    }

    modifier onlyGovernor() {
        require(hasRole(GOVERNOR, msg.sender), "AccessControl: caller is not a governor");
    }
}