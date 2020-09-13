pragma solidity ^0.5.0;

interface IHonestSavings {

    function deposit(uint256 _amount) external returns (uint256);

    function withdraw(uint256 _shares) external returns (uint256);

    function savingsOf(address _account) external view returns (uint256);

    function sharesOf(address _account) external view returns (uint256);

    function totalSavings() external view returns (uint256);

    function totalShares() external view returns (uint256);

    function netValue() external view returns (uint256);

    function apy() external view returns (uint256);

    function swap(address _account, address[] calldata _borrowBAssets, uint256[] calldata _borrows, address[] calldata _supplyBAssets, uint256[] calldata _supplies) external;

    function investments() external view returns (address[] memory, uint256[] memory _amounts);

    function investmentOf(address[] calldata _bAssets) external view returns (uint256[] memory);
}
