// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

abstract contract MockBasketAsset is ERC20, Ownable {

    function mint(address account, uint amount) external onlyOwner returns (bool) {
        _mint(account, amount);
        return true;
    }

    function burn(address account, uint amount) external returns (bool) {
        _burn(account, amount);
        return true;
    }
}

contract MockDAI is MockBasketAsset {

    constructor() public ERC20('Mock DAI', 'DAI') {}
}

contract MockTUSD is MockBasketAsset {

    constructor() public ERC20('Mock TUSD', 'TUSD') {}
}

contract MockUSDC is MockBasketAsset {

    constructor() public ERC20('Mock USDC', 'USDC') {
        _setupDecimals(6);
    }
}

contract MockUSDT is MockBasketAsset {

    constructor() public ERC20('Mock USDT', 'USDT') {
        _setupDecimals(6);
    }
}