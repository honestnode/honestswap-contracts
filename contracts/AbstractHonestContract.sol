// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;

import {Initializable} from '@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol';
import {AccessControlUpgradeSafe} from '@openzeppelin/contracts-ethereum-package/contracts/access/AccessControl.sol';

abstract contract AbstractHonestContract is Initializable, AccessControlUpgradeSafe {

    bytes32 public constant ASSET = keccak256("HONEST_ASSET");
    bytes32 public constant ASSET_MANAGER = keccak256("HONEST_ASSET_MANAGER");
    bytes32 public constant VAULT = keccak256("HONEST_VAULT");
    bytes32 public constant SAVINGS = keccak256("HONEST_SAVINGS");
    bytes32 public constant GOVERNOR = keccak256("HONEST_GOVERNOR");

    function initialize() internal {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    modifier onlyAssetManager {
        require(hasRole(ASSET_MANAGER, msg.sender), "AccessControl: caller is not the AssetManager contract");
        _;
    }

    modifier onlyVault {
        require(hasRole(VAULT, msg.sender), "AccessControl: caller is not the Vault contract");
        _;
    }

    modifier onlySavings {
        require(hasRole(SAVINGS, msg.sender), "AccessControl: caller is not the Savings contract");
        _;
    }

    modifier onlyGovernor {
        require(hasRole(GOVERNOR, msg.sender), "AccessControl: caller is not a governor");
        _;
    }
}