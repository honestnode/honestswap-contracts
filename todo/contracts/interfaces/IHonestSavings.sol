pragma solidity ^0.6.0;

interface IHonestSavings {

    function initialize(address _hAssetContract, address _basketContract, address _investmentContract, address _feeContract, address _bonusContract)
    external;

    function deposit(uint _amount) external returns (uint);

    function withdraw(uint _shares) external returns (uint);

    function savingsOf(address _account) external view returns (uint);

    function sharesOf(address _account) external view returns (uint);

    function totalSavings() external view returns (uint);

    function totalShares() external view returns (uint);

    function sharePrice() external view returns (uint);

    function totalValue() external view returns (uint);

    function updateApy() external;

    function apy() external view returns (int256);

    function swap(address _account, address[] calldata _bAssets, uint[] calldata _borrows, address[] calldata _sAssets, uint[] calldata _supplies)
    external;

    function investments() external view returns (address[] memory, uint[] memory, uint);

    function investmentOf(address bAsset) external view returns (uint);
}
