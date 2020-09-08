pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Initializable} from "@openzeppelin/upgrades/contracts/Initializable.sol";
import {InitializablePausableModule} from "./common/InitializablePausableModule.sol";
import {InitializableReentrancyGuard} from "./common/InitializableReentrancyGuard.sol";
import {IHonestBasket} from "./interface/IHonestBasket.sol";
import {IPlatformIntegration} from "./interface/IPlatformIntegration.sol";

contract HonestBasket is
Initializable,
IHonestBasket,
InitializablePausableModule,
InitializableReentrancyGuard
{

    using SafeMath for uint256;

    // Events for Basket composition changes
    event BassetAdded(address indexed bAsset, address integrator);
    event BassetRemoved(address indexed bAsset);
    event BasketWeightsUpdated(address[] bAssets, uint256[] maxWeights);
    event BassetStatusChanged(address indexed bAsset, BassetStatus status);
    event BasketStatusChanged();
    event TransferFeeEnabled(address indexed bAsset, bool enabled);

    // hAsset linked to the manager (const)
    address public hAsset;

    uint256 private hAssetPoolBalance;

    // Struct holding Basket details
    Basket public basket;
    // Mapping holds bAsset token address => array index
    mapping(address => uint8) private bAssetsMap;
    // Holds relative addresses of the integration platforms
    address[] public integrations;


    /**
     * @dev Initialization function for upgradable proxy contract.
     *      This function should be called via Proxy just after contract deployment.
     * @param _nexus            Address of system Nexus
     * @param _hAsset           Address of the mAsset whose Basket to manage
     * @param _bAssets          Array of erc20 bAsset addresses
     * @param _integrators      Matching array of the platform intergations for bAssets
     * @param _weights          Weightings of each bAsset, summing to 1e18
     * @param _hasTransferFees  Bool signifying if this bAsset has xfer fees
     */
    function initialize(
        address _nexus,
        address _hAsset,
        address[] calldata _bAssets,
        address[] calldata _integrators,
        uint256[] calldata _weights,
        bool[] calldata _hasTransferFees
    )
    external
    initializer
    {
        InitializableReentrancyGuard._initialize();
        InitializablePausableModule._initialize(_nexus);

        require(_hAsset != address(0), "hAsset address is zero");
        require(_bAssets.length > 0, "Must initialise with some bAssets");
        hAsset = _hAsset;

        // Defaults
        basket.maxBassets = uint8(10);

        for (uint256 i = 0; i < _bAssets.length; i++) {
            _addBasset(
                _bAssets[i],
                _integrators[i],
                _hasTransferFees[i]
            );
        }
    }

    /**
     * @dev Verifies that the caller either Manager or Gov
     */
    modifier managerOrGovernor() {
        require(
            _manager() == msg.sender || _governor() == msg.sender,
            "Must be manager or governor");
        _;
    }

    /**
     * @dev Verifies that the caller is governed mAsset
     */
    modifier onlyHasset() {
        require(hAsset == msg.sender, "Must be called by hAsset");
        _;
    }

    /***************************************
                POOL BALANCE
    ****************************************/
    function increasePoolBalance(
        uint8 _bAssetIndex,
        uint256 _increaseAmount)
    external
    onlyHasset
    nonReentrant
    {
        Basset memory bAsset = _getBasset(_bAssetIndex);
        bAsset.poolBalance = bAsset.poolBalance.add(_increaseAmount);
    }

    function increasePoolBalances(
        uint8[] calldata _bAssetIndices,
        uint256[] calldata _increaseAmounts)
    external
    onlyHasset
    nonReentrant
    {
        uint256 len = _bAssetIndices.length;
        require(len > 0 && len == _increaseAmounts.length, "Input array mismatch");
        for (uint i = 0; i < len; i++) {
            uint8 index = _bAssetIndices[i];
            Basset memory bAsset = _getBasset(index);
            uint256 amount = _increaseAmounts[i];
            bAsset.poolBalance = bAsset.poolBalance.add(amount);
        }
    }

    function decreasePoolBalance(
        uint8 _bAssetIndex,
        uint256 _decreaseAmount)
    external
    onlyHasset
    nonReentrant
    {
        Basset memory bAsset = _getBasset(_bAssetIndex);
        bAsset.poolBalance = bAsset.poolBalance.sub(_decreaseAmount);
    }

    function decreasePoolBalances(
        uint8[] calldata _bAssetIndices,
        uint256[] calldata _decreaseAmounts)
    external
    onlyHasset
    nonReentrant
    {
        uint256 len = _bAssetIndices.length;
        require(len > 0 && len == _decreaseAmounts.length, "Input array mismatch");
        for (uint i = 0; i < len; i++) {
            uint8 index = _bAssetIndices[i];
            Basset memory bAsset = _getBasset(index);
            bAsset.poolBalance = bAsset.poolBalance.sub(_decreaseAmounts[i]);
        }
    }

    /***************************************
                SAVING BALANCE
    ****************************************/
    /**
     * @dev Called by only hAsset, to add units to
     *      storage after they have been deposited into the pool
     * @param _bAssetIndex      Index of the bAsset
     * @param _increaseAmount   Units deposited
     */
    function increaseSavingBalance(
        uint8 _bAssetIndex,
        uint256 _increaseAmount
    )
    external
    onlyHasset
    nonReentrant
    {
        Basset memory bAsset = _getBasset(_bAssetIndex);
        bAsset.savingBalance = bAsset.savingBalance.add(_increaseAmount);
    }

    /**
     * @dev Called by only hAsset, to add units to
     *      storage after they have been deposited into the pool
     * @param _bAssetIndices    Array of bAsset indexes
     * @param _increaseAmount   Units deposited
     */
    function increaseSavingBalances(
        uint8[] calldata _bAssetIndices,
        uint256[] calldata _increaseAmount
    )
    external
    onlyHasset
    nonReentrant
    {
        uint256 len = _bAssetIndices.length;
        require(len > 0 && len == _increaseAmount.length, "Input array mismatch");
        for (uint i = 0; i < len; i++) {
            uint8 index = _bAssetIndices[i];
            Basset memory bAsset = _getBasset(index);
            bAsset.savingBalance = bAsset.savingBalance.add(_increaseAmount[i]);
        }
    }

    /**
     * @dev Called by hAsset after redeeming tokens. Simply reduce the balance in the vault
     * @param _bAssetIndex      Index of the bAsset
     * @param _decreaseAmount   Units withdrawn
     */
    function decreaseSavingBalance(
        uint8 _bAssetIndex,
        uint256 _decreaseAmount
    )
    external
    onlyHasset
    nonReentrant
    {
        Basset memory bAsset = _getBasset(_bAssetIndex);
        bAsset.savingBalance = bAsset.savingBalance.sub(_decreaseAmount);
    }

    /**
     * @dev Called by hAsset after redeeming tokens. Simply reduce the balance in the vault
     * @param _bAssetIndices    Array of bAsset indexes
     * @param _decreaseAmount   Units withdrawn
     */
    function decreaseSavingBalances(
        uint8[] calldata _bAssetIndices,
        uint256[] calldata _decreaseAmounts
    )
    external
    onlyHasset
    nonReentrant
    {
        uint256 len = _bAssetIndices.length;
        require(len > 0 && len == _decreaseAmounts.length, "Input array mismatch");
        for (uint i = 0; i < len; i++) {
            uint8 index = _bAssetIndices[i];
            Basset memory bAsset = _getBasset(index);
            bAsset.savingBalance = bAsset.savingBalance.sub(_decreaseAmounts[i]);
        }
    }

    function mintForBalance(uint8[] calldata _bAssetIndices, uint256[] calldata _amounts)
    external
    nonReentrant {
        uint256 len = _bAssetIndices.length;
        require(len > 0 && len == _amounts.length, "Input array mismatch");
        for (uint i = 0; i < len; i++) {
            uint8 index = _bAssetIndices[i];
            Basset memory bAsset = _getBasset(index);
            bAsset.poolBalance = bAsset.poolBalance.add(_amounts[i]);
        }
    }

    function withdrawForBalance(uint8[] calldata _bAssetIndices, uint256[] calldata _amounts)
    external
    nonReentrant {
        uint256 len = _bAssetIndices.length;
        require(len > 0 && len == _amounts.length, "Input array mismatch");
        for (uint i = 0; i < len; i++) {
            uint8 index = _bAssetIndices[i];
            Basset memory bAsset = _getBasset(index);
            bAsset.poolBalance = bAsset.poolBalance.sub(_amounts[i]);
        }
    }

    function depositForBalance(uint8[] calldata _bAssetIndices, uint256[] calldata _amounts)
    external
    nonReentrant {
        uint256 len = _bAssetIndices.length;
        require(len > 0 && len == _amounts.length, "Input array mismatch");
        for (uint i = 0; i < len; i++) {
            uint8 index = _bAssetIndices[i];
            Basset memory bAsset = _getBasset(index);
            bAsset.savingBalance = bAsset.savingBalance.add(_amounts[i]);
            bAsset.poolBalance = bAsset.poolBalance.sub(_amounts[i]);
        }
    }

    function redeemForBalance(uint8[] calldata _bAssetIndices, uint256[] calldata _amounts)
    external
    nonReentrant {
        uint256 len = _bAssetIndices.length;
        require(len > 0 && len == _amounts.length, "Input array mismatch");
        for (uint i = 0; i < len; i++) {
            uint8 index = _bAssetIndices[i];
            Basset memory bAsset = _getBasset(index);
            bAsset.savingBalance = bAsset.savingBalance.sub(_amounts[i]);
            bAsset.poolBalance = bAsset.poolBalance.add(_amounts[i]);
        }
    }

    /***************************************
                BASKET MANAGEMENT
    ****************************************/

    /**
     * @dev External func to allow the Governor to conduct add operations on the Basket
     * @param _bAsset               Address of the ERC20 token to add to the Basket
     * @param _integration          Address of the vault integration to deposit and withdraw
     * @param _isTransferFeeCharged Bool - are transfer fees charged on this bAsset
     * @return index                Position of the bAsset in the Basket
     */
    function addBasset(address _bAsset, address _integration, bool _isTransferFeeCharged)
    external
    onlyGovernor
    returns (uint8 index)
    {
        index = _addBasset(
            _bAsset,
            _integration,
            _isTransferFeeCharged
        );
    }

    /**
     * @dev Adds a bAsset to the Basket, fetching its decimals and calculating the Ratios
     * @param _bAsset               Address of the ERC20 token to add to the Basket
     * @param _integration          Address of the Platform Integration
     * @param _isTransferFeeCharged Bool - are transfer fees charged on this bAsset
     * @return index                Position of the bAsset in the Basket
     */
    function _addBasset(
        address _bAsset,
        address _integration,
        bool _isTransferFeeCharged
    )
    internal
    returns (uint8 index)
    {
        require(_bAsset != address(0), "bAsset address must be valid");
        require(_integration != address(0), "Integration address must be valid");

        (bool alreadyInBasket,) = _isAssetInBasket(_bAsset);
        require(!alreadyInBasket, "bAsset already exists in Basket");

        uint8 numberOfBassetsInBasket = uint8(basket.bassets.length);
        require(numberOfBassetsInBasket < basket.maxBassets, "Max bAssets in Basket");

        bAssetsMap[_bAsset] = numberOfBassetsInBasket;

        integrations.push(_integration);
        basket.bassets.push(Basset({
            addr : _bAsset,
            status : BassetStatus.Normal,
            poolBalance : 0,
            savingBalance : 0,
            feeBalance : 0,
            platformBalance : 0,
            isTransferFeeCharged : _isTransferFeeCharged
            }));

        emit BassetAdded(_bAsset, _integration);

        index = numberOfBassetsInBasket;
    }

    /**
     * @dev Update transfer fee flag for a given bAsset, should it change its fee practice
     * @param _bAsset   bAsset address
     * @param _flag         Charge transfer fee when its set to 'true', otherwise 'false'
     */
    function setTransferFeesFlag(address _bAsset, bool _flag)
    external
    managerOrGovernor
    {
        (bool exist, uint8 index) = _isAssetInBasket(_bAsset);
        require(exist, "bAsset does not exist");
        basket.bassets[index].isTransferFeeCharged = _flag;

        emit TransferFeeEnabled(_bAsset, _flag);
    }


    /**
     * @dev Removes a specific Asset from the Basket, given that its target/collateral
     *      level is already 0, throws if invalid.
     * @param _assetToRemove The asset to remove from the basket
     */
    function removeBasset(address _assetToRemove)
    external
    managerOrGovernor
    {
        _removeBasset(_assetToRemove);
    }

    /**
     * @dev Removes a specific Asset from the Basket, given that its target/collateral
     *      level is already 0, throws if invalid.
     * @param _assetToRemove The asset to remove from the basket
     */
    function _removeBasset(address _assetToRemove) internal {
        (bool exists, uint8 index) = _isAssetInBasket(_assetToRemove);
        require(exists, "bAsset does not exist");

        uint256 len = basket.bassets.length;
        Basset memory bAsset = basket.bassets[index];

        require(bAsset.poolBalance == 0, "bAsset pool must be empty");
        require(bAsset.savingBalance == 0, "bAsset saving must be empty");
        require(bAsset.feeBalance == 0, "bAsset fee must be empty");
        require(bAsset.status != BassetStatus.Liquidating, "bAsset must be active");

        uint8 lastIndex = uint8(len.sub(1));
        if (index == lastIndex) {
            basket.bassets.pop();
            bAssetsMap[_assetToRemove] = 0;
            integrations.pop();
        } else {
            // Swap the bassets
            basket.bassets[index] = basket.bassets[lastIndex];
            basket.bassets.pop();
            Basset memory swappedBasset = basket.bassets[index];
            // Update bassetsMap
            bAssetsMap[_assetToRemove] = 0;
            bAssetsMap[swappedBasset.addr] = index;
            // Update integrations
            integrations[index] = integrations[lastIndex];
            integrations.pop();
        }

        emit BassetRemoved(bAsset.addr);
    }


    /***************************************
                    GETTERS
    ****************************************/

    /**
     * @dev Get basket details for `HassetStructs.Basket`
     * @return b   Basket struct
     */
    function getBasket()
    external
    view
    returns (Basket memory b)
    {
        b = basket;
    }

    /**
     * @dev Prepare given bAsset for Forging. Currently returns integrator
     *      and essential minting info.
     * @param _bAsset    Address of the bAsset
     * @return props     Struct of all relevant Forge information
     */
    function prepareForgeBasset(address _bAsset)
    external
    whenNotPaused
    returns (bool isValid, BassetDetails memory bInfo)
    {
        (bool exists, uint8 idx) = _isAssetInBasket(_bAsset);
        require(exists, "bAsset does not exist");
        isValid = true;
        bInfo = BassetDetails({
            bAsset : basket.bassets[idx],
            integrator : integrations[idx],
            index : idx
            });
    }

    /**
     * @dev Prepare given bAssets for swapping
     * @param _input     Address of the input bAsset
     * @param _output    Address of the output bAsset
     * @param _isMint    Is this swap actually a mint? i.e. output == address(mAsset)
     * @return props     Struct of all relevant Forge information
     */
    function prepareSwapBassets(address _input, address _output, bool _isMint)
    external
    view
    whenNotPaused
    returns (bool, string memory, BassetDetails memory, BassetDetails memory)
    {
        BassetDetails memory input = BassetDetails({
            bAsset : basket.bassets[0],
            integrator : address(0),
            index : 0
            });
        BassetDetails memory output = input;

        // Fetch input bAsset
        (bool inputExists, uint8 inputIdx) = _isAssetInBasket(_input);
        if (!inputExists) {
            return (false, "Input asset does not exist", input, output);
        }
        input = BassetDetails({
            bAsset : basket.bassets[inputIdx],
            integrator : integrations[inputIdx],
            index : inputIdx
            });

        // If this is a mint, we don't need output bAsset
        if (_isMint) {
            return (true, "", input, output);
        }

        // Fetch output bAsset
        (bool outputExists, uint8 outputIdx) = _isAssetInBasket(_output);
        if (!outputExists) {
            return (false, "Output asset does not exist", input, output);
        }
        output = BassetDetails({
            bAsset : basket.bassets[outputIdx],
            integrator : integrations[outputIdx],
            index : outputIdx
            });
        return (true, "", input, output);
    }

    /**
     * @dev Prepare given bAsset addresses for Forging. Currently returns integrator
     *      and essential minting info for each bAsset
     * @param _bAssets   Array of bAsset addresses with which to forge
     * @return props     Struct of all relevant Forge information
     */
    function prepareForgeBassets(
        address[] calldata _bAssets
    )
    external
    whenNotPaused
    returns (BassetPropsMulti memory props)
    {
        // Pass the fetching logic to the internal view func to reduce SLOAD cost
        (Basset[] memory bAssets, uint8[] memory indexes, address[] memory integrators) = _fetchForgeBassets(_bAssets);
        props = BassetPropsMulti({
            isValid : true,
            bAssets : bAssets,
            integrators : integrators,
            indexes : indexes
            });
    }

    /**
     * @dev Prepare given bAsset addresses for props multi. Currently returns integrator
     *      and essential minting info for each bAsset
     * @return props     Struct of all relevant Forge information
     */
    function preparePropsMulti()
    external
    view
    whenNotPaused
    returns (BassetPropsMulti memory props)
    {
        (Basset[] memory bAssets, uint256 len) = _getBassets();
        address[] memory orderedIntegrators = new address[](len);
        uint8[] memory indexes = new uint8[](len);
        for (uint8 i = 0; i < len; i++) {
            orderedIntegrators[i] = integrations[i];
            indexes[i] = i;
        }
        props = BassetPropsMulti({
            isValid : true,
            bAssets : bAssets,
            integrators : orderedIntegrators,
            indexes : indexes
            });
    }

    /**
     * @dev Internal func to fetch an array of bAssets and their integrators from storage
     * @param _bAssets       Array of non-duplicate bAsset addresses with which to forge
     * @return bAssets       Array of bAsset structs for the given addresses
     * @return indexes       Array of indexes for the given addresses
     * @return integrators   Array of integrators for the given addresses
     */
    function _fetchForgeBassets(address[] memory _bAssets)
    internal
    view
    returns (
        Basset[] memory bAssets,
        uint8[] memory indexes,
        address[] memory integrators
    )
    {
        uint8 len = uint8(_bAssets.length);

        bAssets = new Basset[](len);
        integrators = new address[](len);
        indexes = new uint8[](len);

        // Iterate through the input
        for (uint8 i = 0; i < len; i++) {
            address current = _bAssets[i];

            // If there is a duplicate here, throw
            // Gas costs do not incur SLOAD
            for (uint8 j = i + 1; j < len; j++) {
                require(current != _bAssets[j], "Must have no duplicates");
            }

            // Fetch and log all the relevant data
            (bool exists, uint8 index) = _isAssetInBasket(current);
            require(exists, "bAsset must exist");
            indexes[i] = index;
            bAssets[i] = basket.bassets[index];
            integrators[i] = integrations[index];
        }
    }

    /**
     * @dev Get data for a all bAssets in basket
     * @return bAssets  Struct[] with full bAsset data
     * @return len      Number of bAssets in the Basket
     */
    function getBassets()
    external
    view
    returns (
        Basset[] memory bAssets,
        uint256 len
    )
    {
        return _getBassets();
    }

    /**
     * @dev Get data for a specific bAsset, if it exists
     * @param _bAsset   Address of bAsset
     * @return bAsset  Struct with full bAsset data
     */
    function getBasset(address _bAsset)
    external
    view
    returns (Basset memory bAsset)
    {
        (bool exists, uint8 index) = _isAssetInBasket(_bAsset);
        require(exists, "bAsset must exist");
        bAsset = _getBasset(index);
    }

    /**
     * @dev Get current integrator for a specific bAsset, if it exists
     * @param _bAsset      Address of bAsset
     * @return integrator  Address of current integrator
     */
    function getBassetIntegrator(address _bAsset)
    external
    view
    returns (address integrator)
    {
        (bool exists, uint8 index) = _isAssetInBasket(_bAsset);
        require(exists, "bAsset must exist");
        integrator = integrations[index];
    }

    function _getBassets()
    internal
    view
    returns (
        Basset[] memory bAssets,
        uint256 len
    )
    {
        bAssets = basket.bassets;
        len = basket.bassets.length;
    }

    function _getBasset(uint8 _bAssetIndex)
    internal
    view
    returns (Basset memory bAsset)
    {
        require(_bAssetIndex >= 0 && _bAssetIndex < basket.bassets.length, "bAsset index invalid");
        bAsset = basket.bassets[_bAssetIndex];
    }


    /***************************************
                    HELPERS
    ****************************************/

    /**
     * @dev Checks if a particular asset is in the basket
     * @param _asset   Address of bAsset to look for
     * @return exists  bool to signal that the asset is in basket
     * @return index   uint256 Index of the bAsset
     */
    function _isAssetInBasket(address _asset)
    internal
    view
    returns (bool exists, uint8 index)
    {
        index = bAssetsMap[_asset];
        if (index == 0) {
            if (basket.bassets.length == 0) {
                return (false, 0);
            }
            return (basket.bassets[0].addr == _asset, 0);
        }
        return (true, index);
    }

}
