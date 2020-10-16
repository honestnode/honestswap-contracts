import {BuidlerRuntimeEnvironment, DeployFunction} from '@nomiclabs/buidler/types';
import {utils} from 'ethers';
import {deployStandardContract, deployUpgradableContract, getUpgradableContract} from '../scripts/HonestContract.deploy';

const deployHonestConfiguration: DeployFunction = async (bre: BuidlerRuntimeEnvironment) => {
  const honestAsset = await getUpgradableContract('HonestAsset');
  const basketAssets = await deployBasketAssets(bre);
  const investments = await deployInvestments(bre);
  await deployUpgradableContract(bre, 'HonestConfiguration', honestAsset.address, basketAssets,
    investments, utils.parseUnits('1', 16), utils.parseUnits('1', 16), utils.parseUnits('8', 17));
};

const deployBasketAssets = async (bre: BuidlerRuntimeEnvironment): Promise<string[]> => {
  switch (bre.network.name) {
    case 'buidlerevm':
      const daiAddress = await deployStandardContract(bre, 'MockDAI');
      const tusdAddress = await deployStandardContract(bre, 'MockTUSD');
      const usdcAddress = await deployStandardContract(bre, 'MockUSDC');
      const usdtAddress = await deployStandardContract(bre, 'MockUSDT');
      return [daiAddress, tusdAddress, usdcAddress, usdtAddress];
    default:
      throw new Error('Not implemented');
  }
};

const deployInvestments = async (bre: BuidlerRuntimeEnvironment): Promise<string[]> => {
  switch (bre.network.name) {
    case 'buidlerevm':
      const supervisor = (await bre.getNamedAccounts())['supervisor'];
      const dai = await bre.ethers.getContract('MockDAI', supervisor);
      const tusd = await bre.ethers.getContract('MockTUSD', supervisor);
      const usdc = await bre.ethers.getContract('MockUSDC', supervisor);
      const usdt = await bre.ethers.getContract('MockUSDT', supervisor);
      const yDAIAddress = await deployStandardContract(bre, 'MockYDAI', dai.address);
      const yTUSDAddress = await deployStandardContract(bre, 'MockYTUSD', tusd.address);
      const yUSDCAddress = await deployStandardContract(bre, 'MockYUSDC', usdc.address);
      const yUSDTAddress = await deployStandardContract(bre, 'MockYUSDT', usdt.address);
      await dai.mint(yDAIAddress, utils.parseUnits('1000', 18));
      await tusd.mint(yTUSDAddress, utils.parseUnits('1000', 18));
      await usdc.mint(yUSDCAddress, utils.parseUnits('1000', 6));
      await usdt.mint(yUSDTAddress, utils.parseUnits('1000', 6));
      return [yDAIAddress, yTUSDAddress, yUSDCAddress, yUSDTAddress];
    default:
      throw new Error('Not implemented');
  }
};

export default deployHonestConfiguration;