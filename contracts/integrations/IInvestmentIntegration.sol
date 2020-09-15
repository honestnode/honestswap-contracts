pragma solidity ^0.5.0;

interface IInvestmentIntegration {

    function initialize(address[] calldata _addresses, address[] calldata _yAddresses) external;

    function assets() external view returns (address[] memory);

    function addAsset(address _address, address _yAddress) external;

    function removeAsset(address _address) external;

    function invest(address _asset, uint256 _amount) external returns (uint256);

    function collect(address _bAsset, uint256 _shares) external returns (uint256);

    function priceOf(address _bAsset) external view returns (uint256);

    function balanceOf(address _bAsset) external view returns (uint256);

    function balances() external view returns (address[] memory, uint256[] memory, uint256);

    function totalBalance() external view returns (uint256);
}