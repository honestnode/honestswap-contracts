const BN = require('bn.js');
const {expectRevert} = require('@openzeppelin/test-helpers');

const BAssetValidatorArtifact = artifacts.require('BAssetValidator');

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";


contract('BAssetValidator', async (accounts) => {


    let bAssetValidator;

    const createContract = async () => {
        bAssetValidator = await BAssetValidatorArtifact.new();
    };

    before(async () => {
        await createContract();
    });

    describe('validate mint', async () => {
        // function validateMint(address _bAsset, uint8 _bAssetStatus, uint256 _bAssetQuantity)
        it('illegal address', async () => {
            await expectRevert.unspecified(
                bAssetValidator.validateMint(ZERO_ADDRESS, 0, 100)
            );
        });
    });

    // describe('validate mint multi', async () => {
    //     // function validateMint(address _bAsset, uint8 _bAssetStatus, uint256 _bAssetQuantity)
    //     it('validate failed', async () => {
    //         await expectRevert.unspecified(
    //             bAssetValidator.validateMint(ZERO_ADDRESS, 0, 100)
    //         );
    //     });
    // });

    // describe('validate mint', async () => {
    //     // function validateMintMulti(address[] calldata _bAssets, uint8[] calldata _bAssetStatus, uint256[] calldata _bAssetQuantities)
    //     it('illegal address', async () => {
    //         await expectRevert.unspecified(
    //             bAssetValidator.validateMint(ZERO_ADDRESS, 0, 100)
    //         );
    //     });
    // });
});
