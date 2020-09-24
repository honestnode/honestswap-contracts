pragma solidity ^0.6.0;

import {ERC20} from '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol';
import {ERC20} from '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol';
import {WhitelistAdminRole} from '@openzeppelin/contracts-ethereum-package/contracts/access/roles/WhitelistAdminRole.sol';

contract IHonestAsset is ERC20, ERC20, WhitelistAdminRole {

    function mint(address account, uint amount) public onlyWhitelistAdmin returns (bool) {
        _mint(account, amount);
        return true;
    }

    function burn(address account, uint amount) public onlyWhitelistAdmin returns (bool) {
        _burnFrom(account, amount);
        return true;
    }
}