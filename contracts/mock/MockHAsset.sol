pragma solidity ^0.5.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

contract MockHAsset is ERC20Mintable, ERC20Detailed {

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    constructor() public ERC20Detailed('Honest USD', 'hUSD', 18) {}
}