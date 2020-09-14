pragma solidity ^0.5.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import "../savings/YearnV2Integration.sol";

contract MockYTokenV2 is yTokenV2, ERC20Mintable, ERC20Detailed {

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    IERC20 private _token;

    function deposit(uint256 _amount) external {
        _token.safeTransferFrom(_msgSender(), address(this), _amount);
        _mint(_msgSender(), _amount);
    }

    function withdraw(uint256 _shares) external {
        _transfer(_msgSender(), address(this), _shares);
        _token.safeTransfer(_msgSender(), _shares);
    }

    function getPricePerFullShare() external view returns (uint256) {
        return uint256(1e18); // value never change
    }

    function _setToken(address _tokenAddress) internal {
        _token = IERC20(_tokenAddress);
    }
}

contract MockYDAI is MockYTokenV2 {

    constructor(address _dai) public ERC20Detailed('Mock yDAI', 'yDAI', 18) {
        _setToken(_dai);
    }
}

contract MockYUSDT is MockYTokenV2 {

    constructor(address _usdt) public ERC20Detailed('Mock yUSDT', 'yUSDT', 6) {
        _setToken(_usdt);
    }
}

contract MockYUSDC is MockYTokenV2 {

    constructor(address _usdc) public ERC20Detailed('Mock yUSDC', 'yUSDC', 6) {
        _setToken(_usdc);
    }
}

contract MockYTUSD is MockYTokenV2 {

    constructor(address _tusd) public ERC20Detailed('Mock yTUSD', 'yTUSD', 18) {
        _setToken(_tusd);
    }
}