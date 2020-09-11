pragma solidity ^0.5.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

contract MockTUSD is ERC20Mintable, ERC20Detailed {

    constructor() public ERC20Detailed('Mock USDC', 'USDC', 6) {}
}