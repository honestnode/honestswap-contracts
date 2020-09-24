pragma solidity ^0.6.0;

import {ERC20UpgradeSafe} from '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol';

contract HNC is ERC20UpgradeSafe {

    constructor(uint _initialSupply) public ERC20('Honest Token', 'HNT') {
        _mint(address(this), _initialSupply);
    }
}