// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;

import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";
import {AccessControlUpgradeSafe} from '@openzeppelin/contracts-ethereum-package/contracts/access/AccessControl.sol';

// Part of the code taken from mStable contract: DelayedProxyAdmin.sol
// Reference: https://github.com/mstable/mStable-contracts/blob/master/contracts/upgradability/DelayedProxyAdmin.sol
// License: https://github.com/mstable/mStable-contracts/blob/master/LICENSE
contract DelayedProxyAdmin is AccessControl {

    using SafeMath for uint;

    event DelayUpdated(uint indexed newDelay);
    event UpgradeProposed(address indexed proxy, address implementation, bytes data);
    event UpgradeCancelled(address indexed proxy);
    event Upgraded(address indexed proxy, address oldImpl, address newImpl, bytes data);

    // Request struct to store proposed upgrade requests
    struct Request {
        address implementation; // New contract implementation address
        bytes data;             // Data to call a function on new contract implementation
        uint timestamp;      // Timestamp when upgrade request is proposed
    }

    bytes32 public constant GOVERNOR = keccak256("HONEST_GOVERNOR");
    uint public constant MINIMUM_DELAY = 2 days;
    uint public constant MAXIMUM_DELAY = 14 days;

    // Opt-out upgrade delay
    uint public delay;

    // ProxyAddress => Request
    mapping(address => Request) public requests;

    constructor(uint delay_) public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(GOVERNOR, _msgSender());
        delay = delay_;
    }

    modifier onlyGovernor {
        require(hasRole(GOVERNOR, msg.sender), "AccessControl: caller must be a governor");
        _;
    }

    function setDelay(uint delay_) external onlyGovernor {
        require(delay_ >= MINIMUM_DELAY, "DelayedProxyAdmin.setDelay: delay must exceed minimum delay");
        require(delay_ <= MAXIMUM_DELAY, "DelayedProxyAdmin.setDelay: delay must not exceed maximum delay");

        delay = delay_;
        emit DelayUpdated(delay);
    }

    /**
     * @dev The Governor can propose a new contract implementation for a given proxy.
     * @param proxy Proxy address which is to be upgraded
     * @param implementation Contract address of new implementation
     * @param data calldata to execute initialization function upon upgrade
     */
    function proposeUpgrade(address proxy, address implementation, bytes calldata data) external onlyGovernor {
        require(proxy != address(0), "Proxy address is zero");
        require(implementation != address(0), "Implementation address is zero");
        require(requests[proxy].implementation == address(0), "Upgrade already proposed");
        validateProxy(proxy, implementation);

        Request storage request = requests[proxy];
        request.implementation = implementation;
        request.data = data;
        request.timestamp = now;

        emit UpgradeProposed(proxy, implementation, data);
    }

    /**
     * @dev The Governor can cancel any existing upgrade request.
     * @param proxy The proxy address of the existing request
     */
    function cancelUpgrade(address proxy) external onlyGovernor {
        require(proxy != address(0), "Proxy address is zero");
        require(requests[proxy].implementation != address(0), "No request found");
        delete requests[proxy];
        emit UpgradeCancelled(proxy);
    }

    /**
     * @dev The Governor can accept upgrade request after opt-out delay over. The function is
     *      `payable`, to forward ETH to initialize function call upon upgrade.
     * @param proxy The address of the proxy
     */
    function acceptUpgradeRequest(address payable proxy) external payable onlyGovernor {
        // proxy is payable, because AdminUpgradeabilityProxy has fallback function
        require(proxy != address(0), "Proxy address is zero");
        Request memory request = requests[proxy];
        require(_isDelayOver(request.timestamp), "Delay not over");

        address newImpl = request.implementation;
        bytes memory data = request.data;

        address oldImpl = getProxyImplementation(proxy);

        // Deleting before to avoid re-entrancy
        delete requests[proxy];

        if (data.length == 0) {
            require(msg.value == 0, "msg.value should be zero");
            TransparentUpgradeableProxy(proxy).upgradeTo(newImpl);
        } else {
            TransparentUpgradeableProxy(proxy).upgradeToAndCall{value: msg.value}(newImpl, data);
        }

        emit Upgraded(proxy, oldImpl, newImpl, data);
    }

    /**
     * @dev Checks that the opt-out delay is over
     * @param timestamp Timestamp when upgrade requested
     * @return Returns `true` when upgrade delay is over, otherwise `false`
     */
    function _isDelayOver(uint timestamp) private view returns (bool) {
        if (timestamp > 0 && now >= timestamp.add(delay))
            return true;
        return false;
    }

    /**
     * @dev Checks the given proxy address is a valid proxy for this contract
     * @param proxy The address of the proxy
     * @param newImpl New implementation contract address
     */
    function validateProxy(address proxy, address newImpl) internal view {
        // Proxy has an implementation
        address currentImpl = getProxyImplementation(proxy);

        // Existing implementation must not be same as new one
        require(newImpl != currentImpl, "Implementation must be different");

        // This contract is the Proxy admin of the given proxy address
        address admin = getProxyAdmin(proxy);
        require(admin == address(this), "Proxy admin not matched");
    }

    /**
     * @dev Returns the admin of a proxy. Only the admin can query it.
     * @param proxy Contract address of Proxy
     * @return The address of the current admin of the proxy.
     */
    function getProxyAdmin(address proxy) public view returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = proxy.staticcall(hex"f851a440");
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current implementation of a proxy.
     * This is needed because only the proxy admin can query it.
     * @param proxy Contract address of Proxy
     * @return The address of the current implementation of the proxy.
     */
    function getProxyImplementation(address proxy) public view returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = proxy.staticcall(hex"5c60da1b");
        require(success, "Call failed");
        return abi.decode(returndata, (address));
    }

    function grantProxyRole(address proxy, bytes32 role, address account) external onlyGovernor {
        require(account != address(0), 'DelayedProxyAdmin.grantRole: account must be valid');

        AccessControlUpgradeSafe(proxy).grantRole(role, account);
    }

    function revokeProxyRole(address proxy, bytes32 role, address account) external onlyGovernor {
        require(account != address(0), 'DelayedProxyAdmin.revokeRole: account must be valid');

        AccessControlUpgradeSafe(proxy).revokeRole(role, account);
    }
}