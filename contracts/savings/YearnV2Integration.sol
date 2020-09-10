pragma solidity ^0.5.0;

import '@openzeppelin/contracts/access/roles/WhitelistedRole.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import "./IInvestmentIntegration.sol";

interface yTokenV2 {
    function deposit(uint256 _amount) external;

    function withdraw(uint256 _shares) external;

    function getPricePerFullShare() public view returns (uint);
}

contract YearnV2Integration is IInvestmentIntegration, WhitelistedRole {

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address[] private _bAssets;
    mapping(address => address) private _contracts;

    function invest(address _bAsset, uint256 _amount) external onlyWhitelisted nonReentrant returns (uint256) {
        required(_amount > 0, "invest must greater than 0");

        address yToken = _contractOf(_bAsset);

        uint256 before = IERC20(yToken).balanceOf(address(this));
        IERC20(_bAsset).safeApprove(yToken, _amount);
        yTokenV2(yToken).deposit(_amount);

        return IERC20(yToken).balanceOf(address(this)).sub(before);
    }

    function collect(address _account, address _bAsset, uint256 _shares) external onlyWhitelisted returns (uint256) {
        required(_shares > 0, "shares must greater than 0");

        yTokenV2 yToken = yTokenV2(_contractOf(_bAsset));
        uint256 amount = _shares.mul(yToken.getPricePerFullShare());
        yToken.withdraw(_shares);

        require(amount <= IERC20(_bAsset).balanceOf(address(this)), "insufficient balance");
        IERC20(_bAsset).safeTransfer(_account, amount);

        return _amount;
    }

    function balanceOf(address _bAsset) external view returns (uint256) {
        address yToken = _contractOf(_bAsset);

        uint256 shares = IERC20(yToken).balanceOf(address(this));
        return yTokenV2(yToken).getPricePerFullShare().mul(shares);
    }

    function totalBalance() external view returns (uint256) {
        int length = _bAssets.length;
        uint256 balance = 0;

        for(int i = 0; i < length; ++i) {
            balance.add(balanceOf(_bAssets[i]));
        }
        return balance;
    }

    function _contractOf(address _bAsset) internal view returns (address) {
        address yToken = _contracts[_bAsset];
        require(yToken != address(0), "can not find any available investment contract");
        return yToken;
    }
}