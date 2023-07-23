// SPDX-License-Identifier: MIT
// Author: tycoon.eth
// Description: Fundraise, buy Alien, flip it, redistribute funds. All without
// the need for a DAO, only this simple contract. This is stETH version.
/*

      ___           ___                    ___           ___
     /  /\         /  /\       ___        /  /\         /  /\
    /  /::\       /  /:/      /__/\      /  /::\       /  /::|
   /  /:/\:\     /  /:/       \__\:\    /  /:/\:\     /  /:|:|
  /  /::\ \:\   /  /:/        /  /::\  /  /::\ \:\   /  /:/|:|__
 /__/:/\:\_\:\ /__/:/      __/  /:/\/ /__/:/\:\ \:\ /__/:/ |:| /\
 \__\/  \:\/:/ \  \:\     /__/\/:/~~  \  \:\ \:\_\/ \__\/  |:|/:/
      \__\::/   \  \:\    \  \::/      \  \:\ \:\       |  |:/:/
      /  /:/     \  \:\    \  \:\       \  \:\_\/       |__|::/
     /__/:/       \  \:\    \__\/        \  \:\         /__/:/
     \__\/         \__\/                  \__\/         \__\/
                    ___
      ___          /  /\       ___         ___
     /  /\        /  /:/      /__/\       /  /\
    /  /::\      /  /:/       \__\:\     /  /::\
   /  /:/\:\    /  /:/        /  /::\   /  /:/\:\
  /  /::\ \:\  /__/:/      __/  /:/\/  /  /::\ \:\
 /__/:/\:\ \:\ \  \:\     /__/\/:/~~  /__/:/\:\_\:\
 \__\/  \:\_\/  \  \:\    \  \::/     \__\/  \:\/:/
      \  \:\     \  \:\    \  \:\          \  \::/
       \__\/      \  \:\    \__\/           \__\/
                   \__\/
*/
pragma solidity ^0.8.20;
//import "hardhat/console.sol";
contract AlienFlipStETH {
    mapping (uint16 => bool) public aliens;
    enum State {
        Procurement, // raising ETH & buying an Alien
        Flip,        // sell the Alien
        Distribute   // distribute profits from Alien
    }
    uint16 public theAlien;             // index of the Alien
    State public state;                 // current state
    ICryptoPunk immutable public punks; // CryptoPunks contract
    uint256 immutable public multiplier;// the multiplier value used to increase the price
    //IERC20 stETH immutable public
    IWstETH immutable public wstETH;
    IStETH immutable public stETH;
    IwETH immutable public wETH;
    // stETH address 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84
    // wstETH address 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0
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
        multiplier = 10;
        stETH = IStETH(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
        wstETH = IWstETH(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
        wETH = IwETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        stETH.approve(address(wstETH), type(uint256).max); // approve wstETH wrapper
        //wETH.approve(address(wstETH), type(uint256).max); // approve wstETH wrapper
    }

    /**
    * @dev accept ETH, convert to wstETH issue token for ETH, 1:1
    */
    receive() external payable {
        if (msg.sender == address(punks)) {
            // we received ETH after a punk sale.
            return;
        }
        require(state == State.Procurement, "invalid state");   // while in the Procurement state
        require(msg.value > 0, "need ETH");
        uint256 amount = stETH.balanceOf(address(this));
        (bool ok, ) = address(stETH).call{value: msg.value}("");// convert ETH to stETH
        require (ok);
        amount = stETH.balanceOf(address(this)) - amount;
        amount = wstETH.wrap(amount);                           // convert stETH to wstETH
        _mint(msg.sender, amount);                              // issue a debt token to the sender
    }

    /**
    * @dev deposit stETH, change to wstETH, mint some tokens as receipt
    */
    function depositStETH(uint256 _amount) external {
        require(state == State.Procurement, "invalid state"); // while in the Procurement state
        require(_amount > 0, "need _amount > 0");
        require(stETH.transferFrom(
            msg.sender,
            address(this),
            _amount), "transfer failed");
        _amount = wstETH.wrap(_amount);                       // convert stETH to wstETH
        _mint(msg.sender, _amount);                           // issue a debt token to the sender
    }

    /**
    * @dev burn tokens and get ETH back. Can call any time during the
    *    Procurement state.
    *    Cannot burn in Flip state. Will switch to Distribute state
    *    once the punk is sold, then burning can commence again.
    *    Burns in the Distribute state will also send profits on top of the
    *    returned ETH.
    * @param _amount how much tokens to burn
    */
    function burn(uint256 _amount) external {
        if (state == State.Procurement) {
            _transfer(msg.sender, address(this), _amount);       // take their token
            _burn(_amount);                                      // burn sender's token
            _amount = wstETH.unwrap(_amount);                    // unwrap to stETH
            stETH.transfer(msg.sender, _amount);                 // return the stETH
            return;                                              // end
        }
        if (state == State.Flip) {
            require(
                punks.punkIndexToAddress(theAlien) != address(this),
                "not flipped");                                  // sold the Alien?
            uint256 revenue = address(this).balance;
            punks.withdraw();                                    // take the ETH out
            revenue = address(this).balance - revenue;           // work out how much ETH we got
            uint256 bal = stETH.balanceOf(address(this));
            (bool ok, ) = address(stETH).call{value: revenue}("");// convert ETH to stETH
            require (ok);
            bal = stETH.balanceOf(address(this)) - bal;
            wstETH.wrap(bal);                                    // wrap stETH to wstETH
            state = State.Distribute;                            // move to the distribution state
        }
        require(state == State.Distribute, "not State.Distribute");
        uint256 bal = balanceOf[msg.sender];
        _transfer(msg.sender, address(this), _amount);           // take their share token
        require(stETH.transfer(
            msg.sender,
            wstETH.unwrap((_amount * 1e13 / totalSupply) *
            wstETH.balanceOf(address(this)) / 1e13)),
            "failed to send stETH");                             // unwrap & send their share stETH
        _burn(_amount);                                          // burn sender's share token
    }


    /**
    * @dev procure can be called by anyone.
    *   The function will attempt to acquire the punk. If the acquisition is
    *   successful, the function will send the stETH payment to the seller.
    *   The seller must use "offerPunkForSaleToAddress" in order for the sale
    *   to work. The punk would need to be listed for a small amount of ETH,
    *   eg. 1 wei.
    */
    function procure(uint16 punkId) external payable  {
        require(state == State.Procurement, "invalid state");
        require(aliens[punkId] == true, "punkId not alien");
        address punkOwner = punks.punkIndexToAddress(punkId); // get the punk owner's address
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
        uint256 amount = wstETH.unwrap(wstETH.balanceOf(address(this)));   // unrwap wstETH to get stETH
        require(stETH.transfer(punkOwner, amount), "failed to send stETH");// pay the stETH payment to the seller
        theAlien = punkId;
        state = State.Flip;                                                // we will now try switch to flipping it
        uint newPrice = amount + (amount / multiplier);                    // sell for 10% more
        punks.offerPunkForSale(punkId, newPrice);
    }

    function getStats(address _user) external view returns (
        uint256[] memory // ret
    ) {
        uint[] memory ret = new uint[](11);
        ret[0] = totalSupply;
        ret[1] = balanceOf[_user];
        ret[2] = theAlien;
        ret[3] = uint256(state);
        ret[4] = address(this).balance;
        ret[5] = uint(uint160(punks.punkIndexToAddress(theAlien)));
        bool isForSale;
        address seller;
        (isForSale,,seller,ret[7] /*minValue*/,)  = punks.punksOfferedForSale(theAlien);
        ret[6] = isForSale ? 1 : 0;
        ret[8] = uint256(uint160(seller));
        ret[9] = wstETH.getStETHByWstETH(balanceOf[_user]); // how much stETH _user has
        ret[10] = wstETH.getStETHByWstETH(totalSupply); // total stETH offered by the contract
        return ret;
    }

    /**
    * ERC20 functionality
    */
    string public constant name = "ALI3N Flip Share";
    string public constant symbol = "ALI3N";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 0;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
    * @dev transfer transfers tokens for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    /**
    * @dev transferFrom transfers tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool) {
        uint256 a = allowance[_from][msg.sender]; // read allowance
        //require(_value <= balanceOf[_from], "value exceeds balance"); // SafeMath already checks this
        if (a != type(uint256).max) {             // not infinite approval
            require(_value <= a, "not approved");
            unchecked{allowance[_from][msg.sender] = a - _value;}
        }
        _transfer(_from, _to, _value);
        return true;
    }
    /**
    * @dev Approve tokens of mount _value to be spent by _spender
    * @param _spender address The spender
    * @param _value the stipend to spend
    */
    function approve(address _spender, uint256 _value) external returns (bool) {
        _approve(msg.sender, _spender, _value);
        return true;
    }
    /**
    * @dev burn some tokens
    * @param _amount The amount to burn
    */
    function _burn(uint256 _amount) internal {
        balanceOf[address(this)] = balanceOf[address(this)] - _amount;
        totalSupply = totalSupply - _amount;
        emit Transfer(address(this), address(0), _amount);
    }

    /**
    * @dev mint new tokens
    * @param _to The address to mint to.
    * @param _amount The amount to be minted.
    */
    function _mint(address _to, uint256 _amount) internal {
        require(_to != address(0), "ERC20: mint to the zero address");
        unchecked {totalSupply = totalSupply + _amount;}
        unchecked {balanceOf[_to] = balanceOf[_to] + _amount;}
        emit Transfer(address(0), _to, _amount);
    }

    /**
    * @dev _transfer transfers tokens from one address to another without checking allowance,
       internal only
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal returns (bool) {
        //require(_value <= balanceOf[_from], "value exceeds balance"); // SafeMath already checks this
        balanceOf[_from] = balanceOf[_from] - _value;
        balanceOf[_to] = balanceOf[_to] + _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev _approve is an unsafe approval, for internal calls only
    * @param _from account to pull funds from
    * @param _spender address that will pull the funds
    * @param _value amount to approve in wei
    */
    function _approve(address _from, address _spender, uint256 _value) internal  {
        allowance[_from][_spender] = _value;
        emit Approval(_from, _spender, _value);
    }

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

interface IwETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}
interface IStETH is IERC20 {
    function submit(address _referral) external payable returns (uint256); // generate stETH by sending ETH
}
interface IWstETH is IERC20 {
    function stEthPerToken() external view returns (uint256);
    function getStETHByWstETH(uint256 _wstETHAmount) external view returns (uint256);
    function unwrap(uint256 _wstETHAmount) external returns (uint256);
    function wrap(uint256 _stETHAmount) external returns (uint256);
}
