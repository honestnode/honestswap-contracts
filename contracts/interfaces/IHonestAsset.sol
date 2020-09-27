// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;

import {ERC20UpgradeSafe} from '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol';

abstract contract IHonestAsset is ERC20UpgradeSafe {

    function mint(address account, uint amount) external virtual returns (bool);

    function burn(address account, uint amount) external virtual returns (bool);
}