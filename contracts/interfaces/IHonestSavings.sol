pragma solidity ^0.5.0;

interface IHonestSavings {

    function initialize(address _hAssetContract, address _basketContract, address _investmentContract, address _feeContract, address _bonusContract)
    external;

    function deposit(uint256 _amount) external returns (uint256);

    function withdraw(uint256 _shares) external returns (uint256);

    function savingsOf(address _account) external view returns (uint256);

    function sharesOf(address _account) external view returns (uint256);

    function totalSavings() external view returns (uint256);

    function totalShares() external view returns (uint256);

    function sharePrice() external view returns (uint256);

    function updateApy() external;

    function apy() external view returns (int256);

    function swap(address _account, address[] calldata _bAssets, uint256[] calldata _borrows, address[] calldata _sAssets, uint256[] calldata _supplies)
    external;

    function investments() external view returns (address[] memory, uint256[] memory _amounts);

    function investmentOf(address[] calldata _bAssets) external view returns (uint256[] memory);
}
