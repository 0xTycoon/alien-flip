# Alien Flip

Fundraise, buy an Alien CryptoPunk, flip it, redistribute funds. 
All without the need for a DAO, only this simple contract.

# Rules for alien.sol

* Procurement Phase: During this phase, funds are raised. Anyone can add their 
 ETH by sending ETH directly to the contract. 
* A token will be credited to the sender as a receipt of payment, and used
to record their share.
 Anyone can get their ETH back during this phase, by burning the token.
* Once enough ETH is raised to buy an Alien punk, the `procure` function can
 be called by anyone, and an Alien punk is bought. One requirement of this 
 contract is that the seller of the punk must list it using the 
 `offerPunkForSaleToAddress` function. This is to prevent front-running.
* Flip Phase: After buying the Alien punk, the contract switches to the 
 Flip state. During this state it lists the punk for sale for 10% higher than 
 it bought it for. 
* ETH refunds are not available during the Flip state, as all the ETH was used 
 to buy the punk.
* Distribute Phase: Once the Alien punk is sold in the Flip state, ETH refunds 
 by burning the token can resume. This time everyone will receive 10% extra 
 ETH per each token burned.

# stETH version (alienStETH.sol)

This version fundraises using stETH. This means that the offer is always going
up in terms of ETH, essentially creating a reverse Dutch auction. 
When selling the alien, the owner would need to use the 
`offerPunkForSaleToAddress` function to sell the punk to the alien-flip 
contract, and set the price to 1 wei. The alien-flip contract would need to 
have 1 wei on its balance to pay for the punk, and during the sale, the 
alien-flip contract will send the entire stETH balance to the seller, and
immediately place the punk for sale. 

After flipping the punk, stETH gets distributed based on each share.
Since stETH is a rebasing token, the alien-flip contract uses wstETH under the
hood.

# Using this repo

It's using nodejs and Hardhat, the test is run against a forked Mainnet.

rename `hardhat.config.js.dist` to `hardhat.config.js` and paste in your 
Alchemy API where it says 'YOUR-API-KEY-HERE'

```shell
npx hardhat help
npx hardhat test

```
