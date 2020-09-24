pragma solidity ^0.6.0;

import {ERC20UpgradeSafe} from '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol';
import {AbstractHonestContract} from "./AbstractHonestContract.sol";
import {IHonestAsset} from "./interfaces/IHonestAsset.sol";

contract HonestAsset is IHonestAsset, AbstractHonestContract {

    function initialize(string memory name, string memory symbol) external override initializer() {
        __ERC20_init(name, symbol);
        __AccessControl_init_unchained();
    }

    function mint(address account, uint amount) external override onlyAssetManager returns (bool) {
        _mint(account, amount);
        return true;
    }

    function burn(address account, uint amount) external override onlyAssetManager returns (bool) {
        _burn(account, amount);
        return true;
    }
}