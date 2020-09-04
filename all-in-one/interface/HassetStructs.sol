pragma solidity 0.5.16;

interface HassetStructs {

    /** @dev Stores high level basket info */
    struct Basket {
        /** @dev Array of Bassets currently active */
        Basset[] bassets;
        /** @dev Max number of bAssets that can be present in any Basket */
        uint8 maxBassets;
    }

    /** @dev Stores bAsset info. The struct takes 5 storage slots per Basset */
    struct Basset {
        /** @dev Address of the bAsset */
        address addr;
        /** @dev Status of the basset,  */
        BassetStatus status; // takes uint8 datatype (1 byte) in storage
        /** @dev An ERC20 can charge transfer fee, for example USDT, DGX tokens. */
        bool isTransferFeeCharged; // takes a byte in storage
        /** @dev Amount of the Basset that is held in pool, minted but not saved */
        uint256 poolBalance;
        /** @dev Amount of the Basset that is saved to platform */
        uint256 savingBalance;
        /** @dev Amount of the Basset that is held in platform */
        uint256 platformBalance;
        /** @dev Amount of the swap fee that is held in basket */
        uint256 feeBalance;
    }

    /** @dev Status of the Basset - has it broken its peg? */
    enum BassetStatus {
        Normal,
        Blacklisted,
        Liquidating,
        Liquidated,
        Failed
    }
    /** @dev Internal details on Basset */
    struct BassetDetails {
        Basset bAsset;
        address integrator;
        uint8 index;
    }

    /** @dev All details needed to Forge with multiple bAssets */
    struct ForgePropsMulti {
        bool isValid; // Flag to signify that forge bAssets have passed validity check
        Basset[] bAssets;
        address[] integrators;
        uint8[] indexes;
    }

    /** @dev All details needed for proportionate Redemption */
    struct RedeemPropsMulti {
        Basset[] bAssets;
        address[] integrators;
        uint8[] indexes;
    }
}
