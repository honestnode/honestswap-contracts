pragma solidity 0.5.16;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {InitializableAbstractIntegration} from "./InitializableAbstractIntegration.sol";
import {IyToken} from "./IYfi.sol";
import {HAssetHelpers} from "../util/HAssetHelpers.sol";

/**
 * @title   YfiIntegration
 * @author  HonestSwap. Ltd.
 * @notice  A simple connection to deposit and withdraw bAssets from YFI
 * @dev     VERSION: 1.0
 */
contract YfiIntegration is InitializableAbstractIntegration {


    /***************************************
                    CORE
    ****************************************/

    /**
     * @dev Deposit a quantity of bAsset into the platform. Credited yTokens
     *      remain here in the vault. Can only be called by whitelisted addresses
     * @param _bAsset              Address for the bAsset
     * @param _amount              Units of bAsset to deposit
     * @param _isTokenFeeCharged   Flag that signals if an xfer fee is charged on bAsset
     * @return quantityDeposited   Quantity of bAsset that entered the platform
     */
    function deposit(
        address _bAsset,
        uint256 _amount,
        bool _isTokenFeeCharged
    )
    external
    onlyWhitelisted
    nonReentrant
    returns (uint256 quantityDeposited)
    {
        require(_amount > 0, "Must deposit something");
        // Get the Target token
        IyToken yToken = _getATokenFor(_bAsset);

        // We should have been sent this amount, if not, the deposit will fail
        quantityDeposited = _amount;

        if (_isTokenFeeCharged) {
            // If we charge a fee, account for it
            uint256 prevBal = _checkBalance(yToken);
            yToken.deposit(_amount);
            uint256 newBal = _checkBalance(yToken);
            quantityDeposited = _min(quantityDeposited, newBal.sub(prevBal));
        } else {
            // yTokens are 1:1 for each asset
            yToken.deposit(_amount);
        }

        emit Deposit(_bAsset, address(yToken), quantityDeposited);
    }

    /**
     * @dev Withdraw a quantity of bAsset from the platform. Withdraw
     *      should fail if we have insufficient balance on the platform.
     * @param _receiver     Address to which the bAsset should be sent
     * @param _bAsset       Address of the bAsset
     * @param _amount       Units of bAsset to withdraw
     */
    function withdraw(
        address _receiver,
        address _bAsset,
        uint256 _amount,
        bool _isTokenFeeCharged
    )
    external
    onlyWhitelisted
    nonReentrant
    {
        require(_amount > 0, "Must withdraw something");
        // Get the Target token
        IyToken yToken = _getATokenFor(_bAsset);

        uint256 quantityWithdrawn = _amount;

        // Don't need to Approve yToken, as it gets burned in withdraw()
        IERC20 b = IERC20(_bAsset);
        if (_isTokenFeeCharged) {
            uint256 prevBal = b.balanceOf(address(this));
            yToken.withdraw(_amount);
            uint256 newBal = b.balanceOf(address(this));
            quantityWithdrawn = _min(quantityWithdrawn, newBal.sub(prevBal));
        } else {
            yToken.withdraw(_amount);
        }

        // Send redeemed bAsset to the receiver
        b.safeTransfer(_receiver, quantityWithdrawn);

        emit Withdrawal(_bAsset, address(yToken), quantityWithdrawn);
    }

    /**
     * @dev Get the total bAsset value held in the platform
     *      This includes any interest that was generated since depositing
     *      FYI gradually increases the balances of all yToken holders, as the interest grows
     * @param _bAsset     Address of the bAsset
     * @return balance    Total value of the bAsset in the platform
     */
    function checkBalance(address _bAsset)
    external
    returns (uint256 balance)
    {
        // balance is always with token yToken decimals
        IyToken yToken = _getATokenFor(_bAsset);
        return _checkBalance(yToken);
    }

    /***************************************
                    APPROVALS
    ****************************************/

    /**
     * @dev Re-approve the spending of all bAssets by the Aave lending pool core,
     *      if for some reason is it necessary for example if the address of core changes.
     *      Only callable through Governance.
     */
    function reApproveAllTokens()
    external
    onlyGovernor
    {
        uint256 bAssetCount = bAssetsMapped.length;
        // approve the pool to spend the bAsset
        for (uint i = 0; i < bAssetCount; i++) {
            address bAsset = bAssetsMapped[i];
            HassetHelpers.safeInfiniteApprove(bAsset, bAssetToPToken[bAsset]);
        }
    }

    /**
     * @dev Internal method to respond to the addition of new bAsset / pTokens
     *      We need to approve the YFI lending pool core conrtact and give it permission
     *      to spend the bAsset
     * @param _bAsset Address of the bAsset to approve
     */
    function _abstractSetPToken(address _bAsset, address _pToken)
    internal
    {
        // approve the pool to spend the bAsset
        HassetHelpers.safeInfiniteApprove(_bAsset, _pToken);
    }

    /***************************************
                    HELPERS
    ****************************************/
    /**
     * @dev Get the pToken wrapped in the IyToken interface for this bAsset, to use
     *      for withdrawing or balance checking. Fails if the pToken doesn't exist in our mappings.
     * @param _bAsset  Address of the bAsset
     * @return yToken  Corresponding to this bAsset
     */
    function _getATokenFor(address _bAsset)
    internal
    view
    returns (IyToken)
    {
        address yToken = bAssetToPToken[_bAsset];
        require(yToken != address(0), "yToken does not exist");
        return IyToken(yToken);
    }

    /**
     * @dev Get the total bAsset value held in the platform
     * @param _yToken     yToken for which to check balance
     * @return balance    Total value of the bAsset in the platform
     */
    function _checkBalance(IyToken _yToken)
    internal
    view
    returns (uint256 balance)
    {
        return _yToken.balance();
    }
}
