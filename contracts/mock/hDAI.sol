pragma solidity ^0.5.0;

import '@openzeppelin/contracts/ownership/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import "./hToken.sol";

contract hDAI is ERC20, ERC20Detailed, ReentrancyGuard, Ownable, hToken {

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public dToken;

    constructor () public ERC20Detailed("iearn DAI", "yDAI", 18) {
        dToken = address(0x8AeBEb4C8dAaE29BC46D17082C93EB8c336294cC);
    }

    function setDToken(address _dToken) external onlyOwner nonReentrant {
        dToken = _dToken;
    }

    function deposit(uint256 _amount) external nonReentrant {
        require(_amount > 0, "deposit must be greater than 0");
        IERC20(dToken).safeTransferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);
    }

    function withdraw(uint256 _shares) external nonReentrant {
        require(_shares > 0, "withdraw must be greater than 0");
        uint256 balance = balanceOf(msg.sender);
        require(_shares <= balance, "insufficient balance");

        _burn(msg.sender, _shares);
        uint256 r = _shares.mul(101).div(100);
        IERC20(dToken).safeTransfer(msg.sender, r);
    }

    function balance() external view returns (uint256) {
        return IERC20(dToken).balanceOf(address(this));
    }
}