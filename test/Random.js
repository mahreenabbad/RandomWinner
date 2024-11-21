const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("Random", function () {
  async function runEveryTime() {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const uri = "MyNFT URI";

    const subscriptionId =
      "18519595116180166042061678876817691063258995766210222005326249960568868181746";

    const contractFactory = await ethers.getContractFactory("Random");
    const randomContract = await contractFactory.deploy(subscriptionId);

    return { owner, addr1, addr2, randomContract };
  }
  describe("Random State variables test cases", function () {
    it("should check numWords varisble ", async function () {
      const { randomContract } = await loadFixture(runEveryTime);
      expect(await randomContract.id()).to.equal(1);
    });
  });
});
