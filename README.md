# Alien Flip

Fundraise, buy an Alien CryptoPunk, flip it, redistribute funds. 
All without the need for a DAO, only this simple contract.

# Rules

* Procurement Phase: During this phase, funds are raised. Anyone can add their 
 ETH by sending ETH directly to the contract. A token will be credited to the 
 sender as a receipt of payment. Anyone can get their ETH back during this 
 phase, by burning the token.
* Once enough ETH is raised to buy an Alien punk, the `procure` function can
 be called by anyone, and an Alien punk is bought. One requirement of this 
 contract is that the seller of the punk must list it using the `offerPunkForSaleToAddress` function. This is to prevent front-running.
* Flip Phase: After buying the Alien punk, the contract switches to the 
 Flip state. During this state it lists the punk for sale for 10% higher than 
 it bought it for. 
* ETH refunds are not available during the Flip state, as all the ETH was used 
 to buy the punk.
* Distribute Phase: Once the Alien punk is sold in the Flip state, ETH refunds 
 by burning the token can resume. This time everyone will receive 10% extra 
 ETH per each token burned.

# Using this repo

It's using nodejs and Hardhat, the test is run against a forked Mainnet.

rename `hardhat.config.js.dist` to `hardhat.config.js` and paste in your Alchemy API where it says 'YOUR-API-KEY-HERE'

```shell
npx hardhat help
npx hardhat test

```
