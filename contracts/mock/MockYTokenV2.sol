// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.6.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';

import {yTokenV2} from "../integrations/YearnV2Integration.sol";

abstract contract MockYTokenV2 is yTokenV2, ERC20, Ownable {

    using SafeERC20 for IERC20;
    using SafeMath for uint;

    IERC20 private _token;

    function mint(address account, uint amount) external onlyOwner returns (bool) {
        _mint(account, amount);
        return true;
    }

    function burn(address account, uint amount) external onlyOwner returns (bool) {
        _burn(account, amount);
        return true;
    }

    function deposit(uint _amount) external override {
        _token.safeTransferFrom(_msgSender(), address(this), _amount);
        uint shares = _amount.mul(uint(1e18)).div(getPricePerFullShare());
        _mint(_msgSender(), shares);
    }

    function withdraw(uint _shares) external override {
        _transfer(_msgSender(), address(this), _shares);
        _token.safeTransfer(_msgSender(), _shares.mul(getPricePerFullShare()).div(uint(1e18)));
    }

    function getPricePerFullShare() public override view returns (uint) {
        return block.timestamp.sub(uint(1599170000)).mul(uint(1e12));
    }

    function _setToken(address _tokenAddress) internal {
        _token = IERC20(_tokenAddress);
    }
}

contract MockYDAI is MockYTokenV2 {

    constructor(address _dai) public ERC20('Mock yDAI', 'yDAI') {
        _setToken(_dai);
    }
}

contract MockYUSDT is MockYTokenV2 {

    constructor(address _usdt) public ERC20('Mock yUSDT', 'yUSDT') {
        _setToken(_usdt);
        _setupDecimals(6);
    }
}

contract MockYUSDC is MockYTokenV2 {

    constructor(address _usdc) public ERC20('Mock yUSDC', 'yUSDC') {
        _setToken(_usdc);
        _setupDecimals(6);
    }
}

contract MockYTUSD is MockYTokenV2 {

    constructor(address _tusd) public ERC20('Mock yTUSD', 'yTUSD') {
        _setToken(_tusd);
    }
}