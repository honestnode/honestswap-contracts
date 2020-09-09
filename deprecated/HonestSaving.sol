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
import {IHasset} from "./interface/IHasset.sol";
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

    // Time at which last collection was made
    mapping(address => uint256) public lastPeriodStart;
    mapping(address => uint256) public lastCollection;
    mapping(address => uint256) public periodYield;

    // Amount of collected interest that will be sent to Savings Contract (100%)
    uint256 private savingsRate = 1e18;
    // Utils to help keep interest under check
    uint256 constant private SECONDS_IN_YEAR = 365 days;
    // Theoretical cap on APY to avoid excess inflation
    uint256 constant private MAX_APY = 15e18;
    uint256 constant private TEN_BPS = 1e15;
    uint256 constant private THIRTY_MINUTES = 30 minutes;


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

    /***************************************
               COLLECTION
   ****************************************/

    /**
     * @dev Collects interest from a target mAsset and distributes to the SavingsContract.
     *      Applies constraints such that the max APY since the last fee collection cannot
     *      exceed the "MAX_APY" variable.
     * @param _mAsset       mAsset for which the interest should be collected
     */
    function collectAndDistributeInterest(address _mAsset)
    external
    whenNotPaused
    {
        ISavingsContract savingsContract = savingsContracts[_mAsset];
        require(address(savingsContract) != address(0), "Must have a valid savings contract");

        // Get collection details
        uint256 recentPeriodStart = lastPeriodStart[_mAsset];
        uint256 previousCollection = lastCollection[_mAsset];
        lastCollection[_mAsset] = now;

        // 1. Collect the new interest from the mAsset
        IHasset hAsset = IHasset(_mAsset);
        (uint256 interestCollected, uint256 totalSupply) = hAsset.collectInterest();

        // 2. Update all the time stamps
        //    Avoid division by 0 by adding a minimum elapsed time of 1 second
        uint256 timeSincePeriodStart = HonestMath.max(1, now.sub(recentPeriodStart));
        uint256 timeSinceLastCollection = HonestMath.max(1, now.sub(previousCollection));

        uint256 inflationOperand = interestCollected;
        //    If it has been 30 mins since last collection, reset period data
        if(timeSinceLastCollection > THIRTY_MINUTES) {
            lastPeriodStart[_mAsset] = now;
            periodYield[_mAsset] = 0;
        }
        //    Else if period has elapsed, start a new period from the lastCollection time
        else if(timeSincePeriodStart > THIRTY_MINUTES) {
            lastPeriodStart[_mAsset] = previousCollection;
            periodYield[_mAsset] = interestCollected;
        }
        //    Else add yield to period yield
        else {
            inflationOperand = periodYield[_mAsset].add(interestCollected);
            periodYield[_mAsset] = inflationOperand;
        }

        // 3. Validate that interest is collected correctly and does not exceed max APY
        if(interestCollected > 0) {
            require(
                IERC20(_mAsset).balanceOf(address(this)) >= interestCollected,
                "Must receive hUSD"
            );

            uint256 extrapolatedAPY = _validateCollection(totalSupply, inflationOperand, timeSinceLastCollection);

            emit InterestCollected(_mAsset, interestCollected, totalSupply, extrapolatedAPY);

            // 4. Distribute the interest
            //    Calculate the share for savers (95e16 or 95%)
            uint256 saversShare = interestCollected.mulTruncate(savingsRate);

            //    Call depositInterest on contract
            savingsContract.depositInterest(saversShare);

            emit InterestDistributed(_mAsset, saversShare);
        } else {
            emit InterestCollected(_mAsset, 0, totalSupply, 0);
        }
    }

    /**
     * @dev Validates that an interest collection does not exceed a maximum APY. If last collection
     * was under 30 mins ago, simply check it does not exceed 10bps
     * @param _newSupply               New total supply of the mAsset
     * @param _interest                Increase in total supply since last collection
     * @param _timeSinceLastCollection Seconds since last collection
     */
    function _validateCollection(uint256 _newSupply, uint256 _interest, uint256 _timeSinceLastCollection)
    internal
    pure
    returns (uint256 extrapolatedAPY)
    {
        // e.g. day: (86400 * 1e18) / 3.154e7 = 2.74..e15
        // e.g. 30 mins: (1800 * 1e18) / 3.154e7 = 5.7..e13
        // e.g. epoch: (1593596907 * 1e18) / 3.154e7 = 50.4..e18
        uint256 yearsSinceLastCollection =
        _timeSinceLastCollection.divPrecisely(SECONDS_IN_YEAR);

        // Percentage increase in total supply
        // e.g. (1e20 * 1e18) / 1e24 = 1e14 (or a 0.01% increase)
        // e.g. (5e18 * 1e18) / 1.2e24 = 4.1667e12
        // e.g. (1e19 * 1e18) / 1e21 = 1e16
        uint256 oldSupply = _newSupply.sub(_interest);
        uint256 percentageIncrease = _interest.divPrecisely(oldSupply);

        // e.g. 0.01% (1e14 * 1e18) / 2.74..e15 = 3.65e16 or 3.65% apr
        // e.g. (4.1667e12 * 1e18) / 5.7..e13 = 7.1e16 or 7.1% apr
        // e.g. (1e16 * 1e18) / 50e18 = 2e14
        extrapolatedAPY = percentageIncrease.divPrecisely(yearsSinceLastCollection);

        //      If over 30 mins, extrapolate APY
        if(_timeSinceLastCollection > THIRTY_MINUTES) {
            require(extrapolatedAPY < MAX_APY, "Interest protected from inflating past maxAPY");
        } else {
            require(percentageIncrease < TEN_BPS, "Interest protected from inflating past 10 Bps");
        }
    }

    /***************************************
                MANAGEMENT
    ****************************************/

    /**
     * @dev Withdraws any unallocated interest, i.e. that which has been saved for use
     *      elsewhere in the system, based on the savingsRate
     * @param _mAsset       mAsset to collect from
     * @param _recipient    Address of mAsset recipient
     */
    function withdrawUnallocatedInterest(address _mAsset, address _recipient)
    external
    onlyGovernance
    {
        IERC20 mAsset = IERC20(_mAsset);
        uint256 balance = mAsset.balanceOf(address(this));

        emit InterestWithdrawnByGovernor(_mAsset, _recipient, balance);

        mAsset.safeTransfer(_recipient, balance);
    }

}
