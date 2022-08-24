const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TransferService", () => {

  before(async () => {
    const [owner, user1, user2, treasure] = await ethers.getSigners();
    erc20 = await ethers.getContractFactory("Token");
    transferService = await ethers.getContractFactory("TransferService");

    this.token1 = await erc20.deploy( 1e8);
    await this.token1.deployed();

    this.token2 = await erc20.deploy(1e9);
    await this.token2.deployed();

    this.token3 = await erc20.deploy( 1e10);
    await this.token3.deployed();

    this.service = await transferService.deploy(treasure.address);
    this.service.deployed();
  });

  const createTransfer = async (amount, feeRate) => {

    const fee = Math.floor(amount * feeRate / 100);
    const [owner, user1] = await ethers.getSigners();
    const balanceBefore = await this.token1.balanceOf(user1.address);
    await this.token1.approve(this.service.address, amount);
    let tx = await this.service.createTransfer(this.token1.address, owner.address, user1.address, amount);
    let receipt = await tx.wait();
    let event = receipt.events.find((x) => {
      return x.event == "Transfer"
    });
    expect(event.args.token).to.equal(this.token1.address);
    expect(event.args.sender).to.equal(owner.address);
    expect(event.args.recipient).to.equal(user1.address);
    expect(event.args.amount).to.equal(amount);
    expect(event.args.fee.toString()).to.equal(fee.toString());
    expect(event).to.not.false;

    const balanceAfter = await this.token1.balanceOf(user1.address);
    expect(balanceAfter).to.equal(balanceBefore.add(amount - fee));

  }

  describe("CreateToken", () => {
    it("Check getBalances", async () => {
      const [owner] = await ethers.getSigners();
      const balances = await this.service.getBalances(owner.address, [this.token1.address, this.token2.address, this.token3.address]);
      expect(balances.length).to.equal(3);
      expect(await this.token1.totalSupply()).to.equal(balances[0]);
      expect(await this.token2.totalSupply()).to.equal(balances[1]);
      expect(await this.token3.totalSupply()).to.equal(balances[2]);
    });
  });

  describe("CreateTranfer", () => {
    it("Check fees", async () => {
      expect(await this.service.getFee(0)).to.equal(1);
      expect(await this.service.getFee(100)).to.equal(2);
      expect(await this.service.getFee(1000)).to.equal(3);
    });
    it("Success transfer 1%", async () => {
      await createTransfer(10, 1);
    });

    it("success transfer 2%", async () => {
      await createTransfer(100, 2);
    });

    it("success transfer 3%", async () => {
      await createTransfer(1000, 3);
    });
  });
});
