const ERC20 = artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol');
const assert = require('assert');

contract('dai', async () => {

  // const dai = await ERC20.at(0x8AeBEb4C8dAaE29BC46D17082C93EB8c336294cC);

  it('dai', async () => {
    // console.log(dai.totalSupply());
    assert.strictEqual(1, 1);
  });
});