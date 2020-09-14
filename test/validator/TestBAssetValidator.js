const BN = require('bn.js');
const {expectRevert} = require('@openzeppelin/test-helpers');

const BAssetValidatorArtifact = artifacts.require('BAssetValidator');

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";


contract('BAssetValidator', async (accounts) => {


    let bAssetValidator;

    const createContract = async () => {
        bAssetValidator = await BAssetValidatorArtifact.new();
    };

    const bAssets = [ZERO_ADDRESS, ZERO_ADDRESS];

    before(async () => {
        await createContract();
    });

    describe('validate mint', async () => {
        // function validateMint(address _bAsset, uint8 _bAssetStatus, uint256 _bAssetQuantity)
        it('validate mint suc', async () => {
            const array = await bAssetValidator.validateMint(ZERO_ADDRESS, 0, 100);
            console.log("array=" + array + ", array[0]=" + array[0] + ", array[1]=" + array[1]);
            expect(true).equal(array[0]);
        });

        it('validate mint failed', async () => {
            const array = await bAssetValidator.validateMint(ZERO_ADDRESS, 1, 10);
            console.log("array=" + array + ", array[0]=" + array[0] + ", array[1]=" + array[1]);
            expect(false).equal(array[0]);
        });
    });

    describe('validate mint multi', async () => {
        // function validateMintMulti(address[] calldata _bAssets, uint8[] calldata _bAssetStatus, uint256[] calldata _bAssetQuantities)
        it('validate suc', async () => {
            const status = [0, 0];
            const quantities = [1, 10];
            const array = await bAssetValidator.validateMintMulti(bAssets, status, quantities);
            console.log("array=" + array + ", array[0]=" + array[0] + ", array[1]=" + array[1]);
            expect(true).equal(array[0]);
        });

        it('validate failed', async () => {
            const status = [0, 1];
            const quantities = [1, 20];
            const array = await bAssetValidator.validateMintMulti(bAssets, status, quantities);
            console.log("array=" + array + ", array[0]=" + array[0] + ", array[1]=" + array[1]);
            expect(false).equal(array[0]);
        });
    });

});
