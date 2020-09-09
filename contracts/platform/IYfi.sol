pragma solidity 0.5.16;

/** @dev FYI interface */
interface IyToken {

    /** @dev deposit */
    function deposit(uint256 _amount) external;
    /** @dev withdraw by shares */
    function withdraw(uint256 _shares) external;
    /** @dev balance of shares */
    function balance() external view returns (uint256);
    /** @dev price per full share */
    function getPricePerFullShare() external view returns (uint256);
}
