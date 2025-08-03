const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("TipJar Contract", function () {

    // We define a fixture to reuse the same setup in every test.
    async function deployTipJarFixture() {
        // Get the signers (accounts)
        const [owner, tipper1, tipper2] = await ethers.getSigners();

        // Deploy the TipJar contract, setting the owner
        const TipJarFactory = await ethers.getContractFactory("TipJar");
        const tipJar = await TipJarFactory.deploy(owner.address);
        await tipJar.waitForDeployment();

        return { tipJar, owner, tipper1, tipper2 };
    }

    describe("Deployment", function () {
        it("Should set the right owner", async function () {
            const { tipJar, owner } = await loadFixture(deployTipJarFixture);
            expect(await tipJar.owner()).to.equal(owner.address);
        });

        it("Should have a totalTipped amount of 0 initially", async function () {
            const { tipJar } = await loadFixture(deployTipJarFixture);
            expect(await tipJar.totalTipped()).to.equal(0);
        });

        it("Should have an initial balance of 0", async function () {
            const { tipJar } = await loadFixture(deployTipJarFixture);
            const balance = await ethers.provider.getBalance(await tipJar.getAddress());
            expect(balance).to.equal(0);
        });
    });

    describe("Sending Tips", function () {
        it("Should allow a user to send a tip and update contract state", async function () {
            const { tipJar, tipper1 } = await loadFixture(deployTipJarFixture);
            const tipAmount = ethers.parseEther("1.0"); // 1 CELO
            const message = "Great work!";

            // Send a tip
            const tx = await tipJar.connect(tipper1).sendTip(message, { value: tipAmount });
            await tx.wait();

            // Check contract balance
            const contractBalance = await ethers.provider.getBalance(await tipJar.getAddress());
            expect(contractBalance).to.equal(tipAmount);

            // Check total tipped amount
            expect(await tipJar.totalTipped()).to.equal(tipAmount);

            // Check tip count
            expect(await tipJar.getTipCount()).to.equal(1);

            // Check the stored tip details
            const latestTips = await tipJar.getLatestTips(1);
            expect(latestTips.length).to.equal(1);
            const tip = latestTips[0];
            expect(tip.sender).to.equal(tipper1.address);
            expect(tip.amount).to.equal(tipAmount);
            expect(tip.message).to.equal(message);
        });

        it("Should emit a TipReceived event", async function () {
            const { tipJar, tipper1 } = await loadFixture(deployTipJarFixture);
            const tipAmount = ethers.parseEther("0.5");
            const message = "Thanks!";

            await expect(tipJar.connect(tipper1).sendTip(message, { value: tipAmount }))
                .to.emit(tipJar, "TipReceived")
                .withArgs(tipper1.address, tipAmount, message);
        });

        it("Should revert if the tip amount is zero", async function () {
            const { tipJar, tipper1 } = await loadFixture(deployTipJarFixture);
            const message = "Free tip!";

            await expect(tipJar.connect(tipper1).sendTip(message, { value: 0 }))
                .to.be.revertedWith("TipJar: Tip amount must be greater than zero.");
        });

        it("Should handle multiple tips correctly", async function () {
            const { tipJar, tipper1, tipper2 } = await loadFixture(deployTipJarFixture);
            const tip1Amount = ethers.parseEther("1.0");
            const tip2Amount = ethers.parseEther("2.5");
            const totalTipped = tip1Amount + tip2Amount;

            await tipJar.connect(tipper1).sendTip("First tip", { value: tip1Amount });
            await tipJar.connect(tipper2).sendTip("Second tip", { value: tip2Amount });

            expect(await tipJar.getTipCount()).to.equal(2);
            expect(await tipJar.totalTipped()).to.equal(totalTipped);
            const contractBalance = await ethers.provider.getBalance(await tipJar.getAddress());
            expect(contractBalance).to.equal(totalTipped);
        });
    });

    describe("Withdrawing Funds", function () {
        beforeEach(async function () {
            // Load fixture and send a tip before each test in this block
            const { tipJar, owner, tipper1 } = await loadFixture(deployTipJarFixture);
            this.tipJar = tipJar;
            this.owner = owner;
            this.tipper1 = tipper1;

            const tipAmount = ethers.parseEther("10.0");
            await this.tipJar.connect(this.tipper1).sendTip("Big tip!", { value: tipAmount });
        });

        it("Should allow the owner to withdraw the entire balance", async function () {
            const ownerBalanceBefore = await ethers.provider.getBalance(this.owner.address);
            const contractBalance = await ethers.provider.getBalance(await this.tipJar.getAddress());

            const tx = await this.tipJar.connect(this.owner).withdraw();
            const receipt = await tx.wait();
            const gasUsed = receipt.gasUsed * receipt.gasPrice;

            const ownerBalanceAfter = await ethers.provider.getBalance(this.owner.address);

            // Owner's balance should increase by the contract balance, minus gas fees
            expect(ownerBalanceAfter).to.equal(ownerBalanceBefore + contractBalance - gasUsed);

            // Contract balance should be zero
            const finalContractBalance = await ethers.provider.getBalance(await this.tipJar.getAddress());
            expect(finalContractBalance).to.equal(0);
        });

        it("Should emit a Withdrawn event", async function () {
            const contractBalance = await ethers.provider.getBalance(await this.tipJar.getAddress());
            await expect(this.tipJar.connect(this.owner).withdraw())
                .to.emit(this.tipJar, "Withdrawn")
                .withArgs(contractBalance, this.owner.address);
        });

        it("Should revert if a non-owner tries to withdraw", async function () {
            await expect(this.tipJar.connect(this.tipper1).withdraw())
                .to.be.revertedWithCustomError(this.tipJar, 'OwnableUnauthorizedAccount');
        });

        it("Should revert if there are no funds to withdraw", async function () {
            // Withdraw the funds first
            await this.tipJar.connect(this.owner).withdraw();

            // Try to withdraw again
            await expect(this.tipJar.connect(this.owner).withdraw())
                .to.be.revertedWith("TipJar: No funds to withdraw.");
        });
    });

    describe("Data Retrieval", function () {
        it("getLatestTips should return the correct number of tips", async function () {
            const { tipJar, tipper1, tipper2 } = await loadFixture(deployTipJarFixture);
            await tipJar.connect(tipper1).sendTip("1", { value: ethers.parseEther("0.1") });
            await tipJar.connect(tipper2).sendTip("2", { value: ethers.parseEther("0.2") });
            await tipJar.connect(tipper1).sendTip("3", { value: ethers.parseEther("0.3") });

            const tips = await tipJar.getLatestTips(2);
            expect(tips.length).to.equal(2);
            expect(tips[0].message).to.equal("3"); // Most recent
            expect(tips[1].message).to.equal("2");
        });

        it("getLatestTips should return all tips if count is larger than total", async function () {
            const { tipJar, tipper1 } = await loadFixture(deployTipJarFixture);
            await tipJar.connect(tipper1).sendTip("1", { value: ethers.parseEther("0.1") });

            const tips = await tipJar.getLatestTips(10);
            expect(tips.length).to.equal(1);
        });

        it("getLatestTips should return an empty array if there are no tips", async function () {
            const { tipJar } = await loadFixture(deployTipJarFixture);
            const tips = await tipJar.getLatestTips(5);
            expect(tips.length).to.equal(0);
        });
    });
});
