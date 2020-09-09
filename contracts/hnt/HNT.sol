pragma solidity ^0.5.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';

contract HNC is ERC20, ERC20Detailed, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    constructor(uint256 _initialSupply) public ERC20Detailed('Honest Token', 'HNT', 18) {
        _mint(address(this), _initialSupply);
    }
}