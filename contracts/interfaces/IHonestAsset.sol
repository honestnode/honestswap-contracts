pragma solidity ^0.5.0;

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {ERC20Detailed} from '@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol';
import {WhitelistAdminRole} from '@openzeppelin/contracts/access/roles/WhitelistAdminRole.sol';

contract IHonestAsset is ERC20, ERC20Detailed, WhitelistAdminRole {

    function mint(address account, uint256 amount) public onlyWhitelistAdmin returns (bool) {
        _mint(account, amount);
        return true;
    }

    function burn(address account, uint256 amount) public onlyWhitelistAdmin returns (bool) {
        _burnFrom(account, amount);
        return true;
    }
}