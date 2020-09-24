pragma solidity ^0.6.0;

import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Mintable.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol';

contract MockStablecoin is ERC20Mintable, ERC20 {

    function burn(address account, uint amount) external returns (bool) {
        _burn(account, amount);
        return true;
    }
}

contract MockDAI is MockStablecoin {

    constructor() public ERC20('Mock DAI', 'DAI', 18) {}
}

contract MockTUSD is MockStablecoin {

    constructor() public ERC20('Mock TUSD', 'TUSD', 18) {}
}

contract MockUSDC is MockStablecoin {

    constructor() public ERC20('Mock USDC', 'USDC', 6) {}
}

contract MockUSDT is MockStablecoin {

    constructor() public ERC20('Mock USDT', 'USDT', 6) {}
}