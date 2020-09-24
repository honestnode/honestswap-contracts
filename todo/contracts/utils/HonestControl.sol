pragma solidity ^0.6.0;

import {AccessControlUpgradeSafe} from '@openzeppelin/contracts-ethereum-package/contracts/access/AccessControl.sol';

abstract contract HonestControl is AccessControlUpgradeSafe {

    bytes32 public constant ASSET_MANAGER = keccak256("ASSET_MANAGER");
    bytes32 public constant VAULT = keccak256("VAULT");
    bytes32 public constant SAVINGS = keccak256("SAVINGS");
}