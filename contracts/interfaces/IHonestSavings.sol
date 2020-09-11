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

    function swap(address _account, address[] calldata _bAssets, uint256[] calldata _borrows, uint256[] calldata _supplies) external;

    // deprecated
    function borrow(address _account, address _bAsset, uint256 _amounts) external returns (uint256);

    // deprecated
    function borrowMulti(address _account, address[] calldata _bAssets, uint256[] calldata _amounts) external returns (uint256);

    // deprecated
    function supply(uint256 _amounts) external returns (uint256);

    function investments() external view returns(address[] memory _bAssets, uint256[] memory _amounts);

    function investmentOf(address[] calldata _bAssets) external view returns(uint256[] memory);
}
