pragma solidity ^0.5.0;

import {ERC20Mintable} from '@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol';
import {ERC20Detailed} from '@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol';

contract MockHAsset is ERC20Mintable, ERC20Detailed {

    constructor() public ERC20Detailed('Honest USD', 'hUSD', 18) {}
}