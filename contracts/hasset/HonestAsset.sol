pragma solidity ^0.5.0;

import {ERC20Detailed} from '@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol';
import {IHonestAsset} from "../interfaces/IHonestAsset.sol";

contract HonestAsset is IHonestAsset {

    constructor(string memory name, string memory symbol) public ERC20Detailed(name, symbol, 18) {}
}