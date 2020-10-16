// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;

import {ERC20UpgradeSafe} from '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol';
import {AbstractHonestContract} from "./AbstractHonestContract.sol";
import {IHonestAsset} from "./interfaces/IHonestAsset.sol";

contract HonestAsset is IHonestAsset, AbstractHonestContract {

    function initialize(address owner, string memory name, string memory symbol) external initializer() {
        require(owner != address(0), 'HonestAsset.initialize: owner address must be valid');
        super.initialize(owner);
        __ERC20_init(name, symbol);
    }

    function mint(address account, uint amount) external override onlyAssetManager returns (bool) {
        _mint(account, amount);
        return true;
    }

    function burn(address account, uint amount) external override onlyAssetManager returns (bool) {
        _burn(account, amount);
        return true;
    }
}