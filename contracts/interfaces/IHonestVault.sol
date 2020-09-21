pragma solidity ^0.5.0;

interface IHonestVault {

    enum Repository { ALL, VAULT, SAVINGS }

    function initialize(address honestAsset, address honestSavings, address[] calldata bAssets) external;

    function honestAsset() external view returns (address);

    function honestSavings() external view returns (address);

    function basketAssets() external view returns (address[] memory, bool[] memory);

    function setHonestAsset(address contractAddress) external;

    function setHonestSavings(address contractAddress) external;

    function addBasketAsset(address contractAddress) external;

    function removeBasketAsset(address contractAddress) external;

    function activateBasketAsset(address contractAddress) external;

    function deactivateBasketAsset(address contractAddress) external;

    function isAssetsAllActive(address[] calldata assets) external returns (bool);

    function balanceOf(address bAsset) external view returns (uint);

    function balances() external view returns (address[] memory, uint[] memory, uint);

    function distributeProportionally(address account, uint amount, Repository repository) external returns (address[] memory, uint[] memory);

    function distributeManually(address account, address[] calldata assets, uint[] calldata amounts, Repository repository) external;
}