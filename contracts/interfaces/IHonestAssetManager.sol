pragma solidity ^0.5.0;

interface IHonestAssetManager {

    function initialize(address assetAddress, address basketAddress, address feeAddress, address bonusAddress) external;

    function honestAsset() external view returns (address);

    function honestVault() external view returns (address);

    function honestFee() external view returns (address);

    function honestBonus() external view returns (address);

    function setHonestAsset(address contractAddress) external;

    function setHonestVault(address contractAddress) external;

    function setHonestFee(address contractAddress) external;

    function setHonestBonus(address contractAddress) external;

    function mint(address[] calldata bAssets, uint[] calldata amounts) external;

    function mintTo(address[] calldata bAssets, uint[] calldata amounts, address recipient) external;

    function redeemProportionally(uint amount) external;

    function redeemProportionallyTo(uint amount, address recipient) external;

    function redeemManually(address[] calldata bAssets, uint[] calldata amounts) external;

    function redeemManuallyTo(address[] calldata bAssets, uint[] calldata amounts, address recipient) external;

    function swap(address from, address to, uint amount) external;

    function swapTo(address from, address to, uint amount, address recipient) external;

    function deposit(address to, uint amount) external returns (uint[] memory);

    function withdraw(address to, address[] calldata assets, uint256[] calldata amounts, uint256 interests) external;
}