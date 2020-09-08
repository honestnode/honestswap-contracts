pragma solidity 0.5.16;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Initializable} from "@openzeppelin/upgrades/contracts/Initializable.sol";
import {InitializablePausableModule} from "./common/InitializablePausableModule.sol";
import {InitializableReentrancyGuard} from "./common/InitializableReentrancyGuard.sol";
import {IHonestSaving} from "./interface/IHonestSaving.sol";
import {HonestMath} from "./util/HonestMath.sol";
import {IHonestBasket} from "./interface/IHonestBasket.sol";
import {IHonestWeight} from "./interface/IHonestWeight.sol";
import {IPlatformIntegration} from "./interface/IPlatformIntegration.sol";

contract HonestSaving is
Initializable,
IHonestSaving,
InitializablePausableModule,
InitializableReentrancyGuard
{

    using SafeMath for uint256;
    using HonestMath for uint256;

    event SavingsDeposited(address indexed saver, uint256 depositAmount, uint256 newSavingBalance);
    event SavingRedeemed(address indexed redeemer, uint256 redeemAmount, uint256 newSavingBalance);

    IERC20 private hUSD;
    IHonestBasket private honestBasket;
    IHonestWeight private honestWeight;

    // hUSD balance
    mapping(address => uint256) private saverBalances;
    uint256 private totalSavings;
    // APY
    uint256 private lastApy;
    uint256 lastApyTs;
    uint8[] apyOrderedBAssetIndices;

    mapping(address => uint256) public lastPeriodStart;
    mapping(address => uint256) public lastCollection;
    mapping(address => uint256) public periodYield;
    uint256 constant private SECONDS_IN_YEAR = 365 days;

    function initialize(
        address _nexus,
        IERC20 _hUSD,
        address _honestBasket,
        address _honestWeight
    )
    external
    initializer {
        InitializablePausableModule._initialize(_nexus);
        InitializableReentrancyGuard._initialize();
        require(address(_hUSD) != address(0), "hUSD address is zero");
        hUSD = _hUSD;

        honestBasket = IHonestBasket(_honestBasket);
        honestWeight = IHonestWeight(_honestWeight);
    }


    function deposit(uint256 _amount) external
    nonReentrant
    returns (uint256 depositReturn){
        require(_amount > 0, "Deposit amount should > 0");
        // hUSD transfer to saving contract
        require(hUSD.transferFrom(msg.sender, address(this), _amount), "Must receive tokens");

        totalSavings = totalSavings.add(_amount);
        address saver = msg.sender;
        uint256 oldSavingBalance = saverBalances[saver];
        uint256 newSavingBalance = oldSavingBalance.add(_amount);
        saverBalances[saver] = newSavingBalance;

        // bAsset deposit to platform
        BassetPropsMulti memory props = honestBasket.preparePropsMulti();

        uint256 len = apyOrderedBAssetIndices.length;
        if (len <= 0) {
            apyOrderedBAssetIndices = props.indexes;
            len = apyOrderedBAssetIndices.length;
        }
        require(len > 0, "ApyOrderedBAssetIndices's len should > 0");
        // for update basket balance
        uint8[] memory bAssetIndices;
        uint256[] memory amounts;
        uint256 index = 0;
        // current amount need to be deposited
        uint256 needDeposit = _amount;
        for (uint256 i = 0; i < len; i++) {
            if (needDeposit <= 0) {
                break;
            }
            uint8 bAssetIndex = apyOrderedBAssetIndices[i];

            Basset memory bAsset = props.bAssets[bAssetIndex];
            address integrator = props.integrators[bAssetIndex];
            uint256 bAssetDepositAmount = 0;
            if (bAsset.poolBalance <= 0) {
                // bAsset has no pool balance, next
                continue;
            }
            if (bAsset.poolBalance >= needDeposit) {
                bAssetDepositAmount = needDeposit;
            } else {
                // not enough
                bAssetDepositAmount = bAsset.poolBalance;
            }
            if (bAssetDepositAmount > 0) {
                uint256 depositedAmount = IPlatformIntegration(integrator).deposit(bAsset.addr, bAssetDepositAmount, bAsset.isTransferFeeCharged);
                if (depositedAmount > 0) {
                    depositReturn = depositReturn.add(depositedAmount);
                    bAssetIndices[index]=bAssetIndex;
                    amounts[index]= depositedAmount;
                    index = index.add(1);
                    if (depositedAmount >= needDeposit) {
                        // deposit done
                        break;
                    }
                    needDeposit = needDeposit.sub(depositedAmount);
                }
            }
        }

        // update basket balance
        if (index > 0) {
            honestBasket.depositForBalance(bAssetIndices, amounts);
        }

        emit SavingsDeposited(saver, _amount, newSavingBalance);
    }

    function redeem(uint256 _amount) external
    nonReentrant
    returns (uint256 hAssetReturned){
        require(_amount > 0, "Redeem amount should > 0");

        address saver = msg.sender;
        uint256 oldSavingBalance = saverBalances[saver];
        require(oldSavingBalance >= _amount, "Redeem amount larger than saving balance ");
        uint256 newSavingBalance = oldSavingBalance.sub(_amount);
        // hUSD transfer back to saver
        require(hUSD.transferFrom(address(this), msg.sender, _amount), "Redeem transfer failed");
        saverBalances[saver] = newSavingBalance;
        totalSavings = totalSavings.sub(_amount);

        hAssetReturned = _amount;
        emit SavingRedeemed(saver, _amount, newSavingBalance);
    }

    function querySavingBalance() external view
    returns (uint256 hAssetBalance){
        hAssetBalance = totalSavings;
    }

    function queryHUsdSavingApy() external view
    returns (uint256 apy, uint256 apyTimestamp){
        apy = lastApy;
        apyTimestamp = lastApyTs;
    }

}
