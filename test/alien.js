const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const {expect} = require("chai");
const {ContractFactory, utils, BigNumber} = require('ethers');

/**
 * Assuming we are at block 17727802
 */
describe("Test Alien flip", function () {
    let alien, punks;
    let owner, simp, elizabeth, alice, bob, satoshi, og;
    let peth = ethers.parseEther;
    before(async function () {
        [owner, simp, elizabeth, alice, bob, satoshi] = await ethers.getSigners();
        let AlienFlip = await ethers.getContractFactory("AlienFlip");
        alien = await AlienFlip.deploy();
        await alien.waitForDeployment();
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [OG_PUNK],
        });
        punks = await hre.ethers.getContractAt(PUNKS_ABI, PUNKS_ADDRESS);
        og = await ethers.provider.getSigner(OG_PUNK); // impersonate the PUNK owner
    });

    it("test the fundraiser", async function () {
        let tx = {
            to: alien.getAddress(),
            // Convert currency unit from ether to wei
            value: ethers.parseEther("1000")
        }
        await expect(await owner.sendTransaction(tx)).to.emit(alien, "Transfer"); // send 1000 ETH
        let supply = await alien.totalSupply();
        expect(supply).to.equal(peth("1000"));
        await expect(await alien.burn(peth("0.1"))).to.emit(alien, "Transfer").withArgs(await alien.getAddress(), "0x0000000000000000000000000000000000000000", peth("0.1")); // we can burn during the fundraiser
        supply = await alien.totalSupply();
        expect(supply).to.equal(peth("999.9")); // supply should decrease by 0.1
        await expect( alien.burn(peth("1000"))).to.emit(alien, "Transfer").to.be.reverted; // cannot burn more than we have
        await expect(await alien.transfer(await simp.getAddress(), peth("999.9"))).to.emit(alien, "Transfer").withArgs(await owner.getAddress(), await simp.getAddress(), peth("999.9")); // transfer token to simp
        expect(await alien.connect(simp).burn(peth("999.9"))).to.emit(alien, "Transfer");
        supply = await alien.totalSupply();
        expect(supply).to.equal(peth("0"));
        await expect(await owner.sendTransaction(tx)).to.emit(alien, "Transfer");
        await expect(await simp.sendTransaction(tx)).to.emit(alien, "Transfer");
        await expect(await elizabeth.sendTransaction(tx)).to.emit(alien, "Transfer");
        await expect(await alice.sendTransaction(tx)).to.emit(alien, "Transfer");
        await expect(await bob.sendTransaction(tx)).to.emit(alien, "Transfer");
        supply = await alien.totalSupply();
        expect(supply).to.equal(peth("5000")); // we should have 5k ETH
    });

    it("procure the punk", async function () {
        await expect(alien.procure(5905)).to.be.revertedWith("please use offerPunkForSaleToAddress");
        await punks.connect(og).offerPunkForSaleToAddress(5905, peth("5000"), await alien.getAddress());
        await expect(await alien.procure(5905)); // should not throw now
        expect(await punks.punkIndexToAddress(5905)).to.equal(await alien.getAddress()); // alien contract is the owner now
        await expect(alien.connect(alice).burn(peth("1000"))).to.be.revertedWith("not flipped");// we cannot burn since the alien has not been flipped
        let stats = await alien.getStats(await owner.getAddress());
        console.log(stats);
        expect(stats[0]).to.equal(peth("5000"));
    })

    it("sell the punk", async function () {
        await expect (await punks.connect(satoshi).buyPunk(5905, {value : peth("5500")})).to.emit(punks, "PunkBought");// Satoshi bought a punk
        await expect(await alien.burn(await alien.balanceOf(await owner.getAddress()))).to.emit(alien, "Transfer").withArgs(await owner.getAddress(), await alien.getAddress(), peth("1000"));
        await expect(await alien.connect(simp).burn(await alien.balanceOf(await simp.getAddress()))).to.emit(alien, "Transfer").withArgs(await simp.getAddress(), await alien.getAddress(), peth("1000"));
        await expect(await alien.connect(elizabeth).burn(await alien.balanceOf(await elizabeth.getAddress()))).to.emit(alien, "Transfer").withArgs(await elizabeth.getAddress(), await alien.getAddress(), peth("1000"));
        await expect(await alien.connect(alice).burn(await alien.balanceOf(await alice.getAddress()))).to.emit(alien, "Transfer").withArgs(await alice.getAddress(), await alien.getAddress(), peth("1000"));
        await expect(await alien.connect(bob).burn(await alien.balanceOf(await bob.getAddress()))).to.emit(alien, "Transfer").withArgs(await bob.getAddress(), await alien.getAddress(), peth("1000"));

        let bal = await ethers.provider.getBalance(alien);
        expect(bal).to.equal(0n); // all ETH withdrawn


    });
});


const OG_PUNK = "0x7Eb28B2f14A59789ec4c782A5DD957F9C8F33f6b";

const PUNKS_ADDRESS = "0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB";
const PUNKS_ABI = [{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"","type":"uint256"}],"name":"punksOfferedForSale","outputs":[{"name":"isForSale","type":"bool"},{"name":"punkIndex","type":"uint256"},{"name":"seller","type":"address"},{"name":"minValue","type":"uint256"},{"name":"onlySellTo","type":"address"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"punkIndex","type":"uint256"}],"name":"enterBidForPunk","outputs":[],"payable":true,"type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"punkIndex","type":"uint256"},{"name":"minPrice","type":"uint256"}],"name":"acceptBidForPunk","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"addresses","type":"address[]"},{"name":"indices","type":"uint256[]"}],"name":"setInitialOwners","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"withdraw","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"imageHash","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"nextPunkIndexToAssign","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"","type":"uint256"}],"name":"punkIndexToAddress","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"standard","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"","type":"uint256"}],"name":"punkBids","outputs":[{"name":"hasBid","type":"bool"},{"name":"punkIndex","type":"uint256"},{"name":"bidder","type":"address"},{"name":"value","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"}],"name":"balanceOf","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"allInitialOwnersAssigned","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"allPunksAssigned","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"punkIndex","type":"uint256"}],"name":"buyPunk","outputs":[],"payable":true,"type":"function"},{"constant":false,"inputs":[{"name":"to","type":"address"},{"name":"punkIndex","type":"uint256"}],"name":"transferPunk","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"punkIndex","type":"uint256"}],"name":"withdrawBidForPunk","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"to","type":"address"},{"name":"punkIndex","type":"uint256"}],"name":"setInitialOwner","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"punkIndex","type":"uint256"},{"name":"minSalePriceInWei","type":"uint256"},{"name":"toAddress","type":"address"}],"name":"offerPunkForSaleToAddress","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"punksRemainingToAssign","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"punkIndex","type":"uint256"},{"name":"minSalePriceInWei","type":"uint256"}],"name":"offerPunkForSale","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"punkIndex","type":"uint256"}],"name":"getPunk","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"}],"name":"pendingWithdrawals","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"punkIndex","type":"uint256"}],"name":"punkNoLongerForSale","outputs":[],"payable":false,"type":"function"},{"inputs":[],"payable":true,"type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"punkIndex","type":"uint256"}],"name":"Assign","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"punkIndex","type":"uint256"}],"name":"PunkTransfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"punkIndex","type":"uint256"},{"indexed":false,"name":"minValue","type":"uint256"},{"indexed":true,"name":"toAddress","type":"address"}],"name":"PunkOffered","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"punkIndex","type":"uint256"},{"indexed":false,"name":"value","type":"uint256"},{"indexed":true,"name":"fromAddress","type":"address"}],"name":"PunkBidEntered","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"punkIndex","type":"uint256"},{"indexed":false,"name":"value","type":"uint256"},{"indexed":true,"name":"fromAddress","type":"address"}],"name":"PunkBidWithdrawn","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"punkIndex","type":"uint256"},{"indexed":false,"name":"value","type":"uint256"},{"indexed":true,"name":"fromAddress","type":"address"},{"indexed":true,"name":"toAddress","type":"address"}],"name":"PunkBought","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"punkIndex","type":"uint256"}],"name":"PunkNoLongerForSale","type":"event"}];