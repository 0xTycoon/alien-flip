// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
* This contract will offer to buy an Alien punk, in exchange for stETH.
* The bought punk will be transferred to the Nouns DAO treasury at
* 0x0BC3807Ec262cB779b38D65b38158acC3bfedE10
*
* To sell your Alien to this contract in exchange for the entire stETH
* balance held by this contract, use the "offerPunkForSaleToAddress"
* functionality ("Offer to Address"), and make sure to sell to this
* contract's address. The price should be for a small amount of ETH,
* say 1 ETH. After making an "Offer to Address", call the procure method of this
* contract with your Alien punk id. You will then receive all of the
* stETH held by this contract in exchange.
*
*/
contract NounsAlien {

    mapping (uint16 => bool) public aliens;
    ICryptoPunk immutable public punks;    // CryptoPunks contract
    IERC20 immutable public stETH;         // stETH address 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84
    address constant public nounsDao = 0x0BC3807Ec262cB779b38D65b38158acC3bfedE10;
    uint64 constant public TIMEOUT = uint64(86400 * 90); // 90 days
    uint64 immutable public deployedAt;
    constructor() {
        aliens[635] = true;
        aliens[2890] = true;
        aliens[3100] = true;
        aliens[3443] = true;
        aliens[5822] = true;
        aliens[5905] = true;
        aliens[6089] = true;
        aliens[7523] = true;
        aliens[7804] = true;
        punks = ICryptoPunk(address(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB));
        stETH = IERC20(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
        deployedAt = uint64(block.timestamp);
    }

    /**
    * @dev give back entire holding of stETH in this contract to the Nouns DAO
    *    after 90 days since deployment of this contract.
    */
    function returnStETH() external {
        if (block.timestamp - deployedAt > TIMEOUT) {
            require(
                stETH.transfer(nounsDao, stETH.balanceOf(address(this))),
                "failed to send stETH"
            );
        }
    }

    /**
    *
    */
    function procure(uint16 punkId) external payable  {
        require(aliens[punkId] == true, "punkId not alien");
        address punkOwner = punks.punkIndexToAddress(punkId);              // get the punk owner's address
        (bool isForSale,,,uint minValue,address onlySellTo) =
            punks.punksOfferedForSale(punkId);
        require(isForSale == true, "punk not for sale");
        require(
            onlySellTo == address(this),
            "please use offerPunkForSaleToAddress"
        );
        require(minValue <= msg.value, "not enough effiriums");            // we need a small amount, eg 1 wei
        punks.buyPunk{value:minValue}(punkId);                             // buy a punk with minimal ETH
        require(punks.punkIndexToAddress(punkId) == address(this), "nope");// did we get it?
        require(
            stETH.transfer(punkOwner, stETH.balanceOf(address(this))),
            "failed to send stETH"
        );                                                                 // pay the stETH payment to the seller
        punks.transferPunk(nounsDao, punkId);                              // send the punk to the Nouns treasury
    }

}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/* 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB */
interface ICryptoPunk {
    //function balanceOf(address account) external view returns (uint256);
    function punkIndexToAddress(uint256 punkIndex) view external returns (address);
    function punksOfferedForSale(uint256 punkIndex) view external returns
    (
        bool,    // isForSale
        uint256, // punkIndex
        address, // seller
        uint256, // minValue in ether
        address  // specify to sell only to a specific person
    );
    function buyPunk(uint punkIndex) external payable;
    //function transferPunk(address to, uint punkIndex) external;
    function offerPunkForSaleToAddress(uint punkIndex, uint minSalePriceInWei, address toAddress) external;
    function offerPunkForSale(uint punkIndex, uint minSalePriceInWei) external;
    function withdraw() external;
    function transferPunk(address to, uint punkIndex) external;
}
