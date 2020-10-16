// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;

import {Initializable} from '@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol';
import {AccessControlUpgradeSafe} from '@openzeppelin/contracts-ethereum-package/contracts/access/AccessControl.sol';

abstract contract AbstractHonestContract is Initializable, AccessControlUpgradeSafe {

    bytes32 private _assetManagerRole;
    bytes32 private _vaultRole;
    bytes32 private _governorRole;

    function initialize() internal initializer() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _assetManagerRole = keccak256("HONEST_ASSET_MANAGER");
        _vaultRole = keccak256("HONEST_VAULT");
        _governorRole = keccak256("HONEST_GOVERNOR");
    }

    function assetManagerRole() external view returns (bytes32) {
        return _assetManagerRole;
    }

    function vaultRole() external view returns (bytes32) {
        return _vaultRole;
    }

    function governorRole() external view returns (bytes32) {
        return _governorRole;
    }

    function transferOwnership(address to) external {
        grantRole(DEFAULT_ADMIN_ROLE, to);
        revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    modifier onlyAssetManager {
        require(hasRole(_assetManagerRole, msg.sender), "AccessControl: caller is not the AssetManager contract");
        _;
    }

    modifier onlyVault {
        require(hasRole(_vaultRole, msg.sender), "AccessControl: caller is not the Vault contract");
        _;
    }

    modifier onlyOwner {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "AccessControl: caller is not the owner");
        _;
    }
}