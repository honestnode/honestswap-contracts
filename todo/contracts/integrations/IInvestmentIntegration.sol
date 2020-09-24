pragma solidity ^0.6.0;

interface IInvestmentIntegration {

    function initialize(address[] calldata _addresses, address[] calldata _yAddresses) external;

    function assets() external view returns (address[] memory);

    function addAsset(address _address, address _yAddress) external;

    function removeAsset(address _address) external;

    function invest(address _asset, uint _amount) external returns (uint);

    function collect(address _bAsset, uint _shares) external returns (uint);

    function priceOf(address _bAsset) external view returns (uint);

    function shareOf(address _bAsset) external view returns (uint);

    function shares() external view returns (address[] memory, uint[] memory, uint, uint);

    function balanceOf(address _bAsset) external view returns (uint);

    function balances() external view returns (address[] memory, uint[] memory, uint);

    function totalBalance() external view returns (uint);
}