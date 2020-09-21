pragma solidity ^0.5.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

contract MockStablecoin is ERC20Mintable, ERC20Detailed {

    function burn(address account, uint256 amount) external returns (bool) {
        _burn(account, amount);
        return true;
    }
}

contract MockDAI is MockStablecoin {

    constructor() public ERC20Detailed('Mock DAI', 'DAI', 18) {}
}

contract MockTUSD is MockStablecoin {

    constructor() public ERC20Detailed('Mock TUSD', 'TUSD', 18) {}
}

contract MockUSDC is MockStablecoin {

    constructor() public ERC20Detailed('Mock USDC', 'USDC', 6) {}
}

contract MockUSDT is MockStablecoin {

    constructor() public ERC20Detailed('Mock USDT', 'USDT', 6) {}
}