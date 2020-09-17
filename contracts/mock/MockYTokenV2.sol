pragma solidity ^0.5.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {ERC20Mintable} from '@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol';
import {ERC20Detailed} from '@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';

import {yTokenV2} from "../integrations/YearnV2Integration.sol";
import {StandardERC20} from "../util/StandardERC20.sol";

contract MockYTokenV2 is yTokenV2, ERC20Mintable, ERC20Detailed {

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    IERC20 private _token;

    function deposit(uint256 _amount) external {
        _token.safeTransferFrom(_msgSender(), address(this), _amount);
        uint256 shares = _amount.mul(uint256(1e18)).div(getPricePerFullShare());
        _mint(_msgSender(), shares);
    }

    function withdraw(uint256 _shares) external {
        _transfer(_msgSender(), address(this), _shares);
        _token.safeTransfer(_msgSender(), _shares.mul(getPricePerFullShare()).div(uint256(1e18)));
    }

    function getPricePerFullShare() public view returns (uint256) {
        // based on block.timestamp, div 10 to make change happened each 10 seconds
        return block.timestamp.div(uint256(10)).sub(uint256(159917000)).mul(uint256(1e13));
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