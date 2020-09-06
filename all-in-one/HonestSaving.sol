pragma solidity 0.5.16;

import {Initializable} from "@openzeppelin/upgrades/contracts/Initializable.sol";
import {InitializablePausableModule} from "./common/InitializablePausableModule.sol";
import {InitializableReentrancyGuard} from "./common/InitializableReentrancyGuard.sol";
import {IHonestSaving} from "./interface/IHonestSaving.sol";

contract HonestSaving is
Initializable,
IHonestSaving,
InitializablePausableModule,
InitializableReentrancyGuard
{

    function initialize(
        address _nexus
    )
    external
    initializer
    {
        InitializablePausableModule._initialize(_nexus);
        InitializableReentrancyGuard._initialize();
    }

    function deposit(uint256 _amount) external
    nonReentrant
    returns (uint256 creditsIssued)
    {

    }

    function redeem(uint256 _amount) external
    nonReentrant
    returns (uint256 hAssetReturned){

    }

    function querySavingBalance() external
    returns (uint256 hAssetBalance)
    {

    }

    function queryHUsdSavingApy() external
    returns (uint256 apy){

    }

}
