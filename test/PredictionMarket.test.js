const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture, time } = require("@nomicfoundation/hardhat-network-helpers");

describe("PredictionMarket Contract", function () {

    // Fixture to deploy the contract and set up accounts
    async function deployPredictionMarketFixture() {
        const [owner, resolver, user1, user2] = await ethers.getSigners();

        const PredictionMarketFactory = await ethers.getContractFactory("PredictionMarket");
        const predictionMarket = await PredictionMarketFactory.deploy(owner.address, 100); // 1% fee
        await predictionMarket.waitForDeployment();

        const marketAddress = await predictionMarket.getAddress();

        return { predictionMarket, marketAddress, owner, resolver, user1, user2 };
    }

    describe("Market Creation", function () {
        it("Should allow a user to create a new market", async function () {
            const { predictionMarket, resolver } = await loadFixture(deployPredictionMarketFixture);
            const question = "Will CELO price be > $1 by end of year?";
            const resolutionTimestamp = (await time.latest()) + time.duration.days(30);

            await expect(predictionMarket.createMarket(question, resolver.address, resolutionTimestamp))
                .to.emit(predictionMarket, "MarketCreated")
                .withArgs(1, question, resolver.address, resolutionTimestamp);

            const market = await predictionMarket.markets(1);
            expect(market.id).to.equal(1);
            expect(market.question).to.equal(question);
            expect(market.resolver).to.equal(resolver.address);
            expect(market.yesToken).to.not.equal(ethers.ZeroAddress);
            expect(market.noToken).to.not.equal(ethers.ZeroAddress);
        });

        it("Should revert if resolution time is in the past", async function () {
            const { predictionMarket, resolver } = await loadFixture(deployPredictionMarketFixture);
            const pastTimestamp = (await time.latest()) - time.duration.seconds(1);
            await expect(predictionMarket.createMarket("Q", resolver.address, pastTimestamp))
                .to.be.revertedWith("Resolution time must be in the future");
        });
    });

    describe("Trading (Buying and Selling Shares)", function () {
        let fixture;
        beforeEach(async function() {
            fixture = await loadFixture(deployPredictionMarketFixture);
            const { predictionMarket, resolver } = fixture;
            const resolutionTimestamp = (await time.latest()) + time.duration.days(1);
            await predictionMarket.createMarket("Test Market", resolver.address, resolutionTimestamp);
        });

        it("Should allow a user to buy shares", async function () {
            const { predictionMarket, user1 } = fixture;
            const marketId = 1;
            const investment = ethers.parseEther("10");

            await expect(predictionMarket.connect(user1).buyShares(marketId, { value: investment }))
                .to.emit(predictionMarket, "SharesBought")
                .withArgs(marketId, user1.address, investment, investment);

            const market = await predictionMarket.markets(marketId);
            expect(market.liquidityPool).to.equal(investment);

            const yesToken = await ethers.getContractAt("OutcomeToken", market.yesToken);
            const noToken = await ethers.getContractAt("OutcomeToken", market.noToken);

            expect(await yesToken.balanceOf(user1.address)).to.equal(investment);
            expect(await noToken.balanceOf(user1.address)).to.equal(investment);
        });

        it("Should allow a user to sell shares", async function () {
            const { predictionMarket, user1 } = fixture;
            const marketId = 1;
            const investment = ethers.parseEther("10");
            const sellAmount = ethers.parseEther("3");

            // User1 buys shares first
            await predictionMarket.connect(user1).buyShares(marketId, { value: investment });

            const balanceBefore = await ethers.provider.getBalance(user1.address);
            
            // Now, sell some back
            const tx = await predictionMarket.connect(user1).sellShares(marketId, sellAmount);
            const receipt = await tx.wait();
            const gasUsed = receipt.gasUsed * receipt.gasPrice;

            const balanceAfter = await ethers.provider.getBalance(user1.address);

            expect(balanceAfter).to.equal(balanceBefore - gasUsed + sellAmount);

            const market = await predictionMarket.markets(marketId);
            const yesToken = await ethers.getContractAt("OutcomeToken", market.yesToken);
            const noToken = await ethers.getContractAt("OutcomeToken", market.noToken);
            const expectedRemaining = investment - sellAmount;

            expect(await yesToken.balanceOf(user1.address)).to.equal(expectedRemaining);
            expect(await noToken.balanceOf(user1.address)).to.equal(expectedRemaining);
        });
    });

    describe("Market Resolution and Redemption", function () {
        let fixture;
        beforeEach(async function() {
            fixture = await loadFixture(deployPredictionMarketFixture);
            const { predictionMarket, resolver, user1, user2 } = fixture;
            const resolutionTimestamp = (await time.latest()) + time.duration.days(1);
            await predictionMarket.createMarket("Resolution Test", resolver.address, resolutionTimestamp);

            // user1 buys 10 sets, user2 buys 5 sets
            await predictionMarket.connect(user1).buyShares(1, { value: ethers.parseEther("10") });
            await predictionMarket.connect(user2).buyShares(1, { value: ethers.parseEther("5") });
        });

        it("Should allow the resolver to resolve the market after the deadline", async function () {
            const { predictionMarket, resolver } = fixture;
            const marketId = 1;
            await time.increase(time.duration.days(2)); // Move time past deadline

            await expect(predictionMarket.connect(resolver).resolveMarket(marketId, 1)) // YES wins
                .to.emit(predictionMarket, "MarketResolved")
                .withArgs(marketId, 1);

            const market = await predictionMarket.markets(marketId);
            expect(market.isResolved).to.be.true;
            expect(market.winningOutcome).to.equal(1);
        });

        it("Should revert if a non-resolver tries to resolve", async function () {
            const { predictionMarket, user1 } = fixture;
            await time.increase(time.duration.days(2));
            await expect(predictionMarket.connect(user1).resolveMarket(1, 1))
                .to.be.revertedWith("Only resolver can call");
        });

        it("Should allow users to redeem winning shares", async function () {
            const { predictionMarket, resolver, user1 } = fixture;
            await time.increase(time.duration.days(2));
            await predictionMarket.connect(resolver).resolveMarket(1, 1); // YES wins

            const user1BalanceBefore = await ethers.provider.getBalance(user1.address);
            const market = await predictionMarket.markets(1);
            const yesToken = await ethers.getContractAt("OutcomeToken", market.yesToken);
            const user1YesBalance = await yesToken.balanceOf(user1.address);

            const tx = await predictionMarket.connect(user1).redeemWinnings(1);
            const receipt = await tx.wait();
            const gasUsed = receipt.gasUsed * receipt.gasPrice;

            const fee = (user1YesBalance * 100n) / 10000n; // 1% fee
            const expectedPayout = user1YesBalance - fee;

            const user1BalanceAfter = await ethers.provider.getBalance(user1.address);
            expect(user1BalanceAfter).to.equal(user1BalanceBefore - gasUsed + expectedPayout);
            expect(await yesToken.balanceOf(user1.address)).to.equal(0);
        });

        it("Should revert when redeeming losing shares", async function () {
            const { predictionMarket, resolver, user1 } = fixture;
            await time.increase(time.duration.days(2));
            await predictionMarket.connect(resolver).resolveMarket(1, 0); // NO wins

            // User1 tries to redeem YES tokens, which are now worthless
            await expect(predictionMarket.connect(user1).redeemWinnings(1))
                .to.be.revertedWith("No winning shares to redeem");
        });
    });

    describe("Admin Functions", function () {
        it("Should allow the owner to change the platform fee", async function () {
            const { predictionMarket, owner } = await loadFixture(deployPredictionMarketFixture);
            const newFee = 250; // 2.5%
            await predictionMarket.connect(owner).setPlatformFee(newFee);
            expect(await predictionMarket.platformFeeBps()).to.equal(newFee);
        });

        it("Should allow the owner to withdraw accumulated fees", async function () {
            const { predictionMarket, owner, resolver, user1 } = await loadFixture(deployPredictionMarketFixture);
            const resolutionTimestamp = (await time.latest()) + time.duration.days(1);
            await predictionMarket.createMarket("Fee Test", resolver.address, resolutionTimestamp);
            await predictionMarket.connect(user1).buyShares(1, { value: ethers.parseEther("10") });
            await time.increase(time.duration.days(2));
            await predictionMarket.connect(resolver).resolveMarket(1, 1);
            await predictionMarket.connect(user1).redeemWinnings(1);

            const fees = await predictionMarket.accumulatedFees();
            expect(fees).to.be.gt(0);

            await expect(predictionMarket.connect(owner).withdrawFees()).to.changeEtherBalances(
                [owner, predictionMarket],
                [fees, -fees]
            );
        });
    });
});
