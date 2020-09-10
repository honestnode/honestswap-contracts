pragma solidity ^0.5.0;

interface IInvestmentIntegration {

    function invest(address _bAsset, uint256 _amount) external returns (uint256);

    function collect(address _account, address _bAsset, uint256 _shares) external returns (uint256);

    function balanceOf(address _bAsset) external view returns (uint256);

    function totalBalance() external view returns (uint256);
}