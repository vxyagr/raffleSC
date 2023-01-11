// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract RaffleV1 is ERC1155, Ownable, Pausable, ERC1155Supply, ReentrancyGuard {

     struct Raffle{
        uint256 id;
        string name;
        uint chainId;
        bool isNFT;
        uint256 tokenId;
        address contractAddress;
        uint256 rewardAmount;
        address raffleOwner;
        uint256 startDate;
        uint256 endDate;
        uint256 treshold;
        uint256 ticketPrice;
        uint256 ticketAmount;
        uint256 sold;
        address winner;
        bool isCancelled;
        bool isActive;
        address [] tickets;

    } 

    Raffle [] raffles;
    uint256 [] featuredRaffleindex;
    uint256 public ticketTax;
    address taxWallet;
    uint256 secretkey;
   // uint [] chainId = [0,1,2];
    string [] chainId = ["Polygon","Ethereum","BSC"];
    mapping (address=>uint256) refundables;
    mapping (address=>uint256[]) rafflesByOwner;
    mapping (uint256=>Raffle) raffleIndex;
    constructor() ERC1155("") {
        taxWallet=0xDA27508B60bdB16f9138BDe0962D9401865f3e1c;
    }

    function setTaxWallet(address addr_)public onlyOwner{
        taxWallet=addr_;
    }
    function getTaxWallet()public view returns(address){
        return taxWallet;
    }
  

    function buyRaffleTicket(uint256 raffleId_,uint256 ticketAmount_) public payable whenNotPaused nonReentrant {
        require(raffles[raffleId_].isActive,"Raffle is not active");
        require((raffles[raffleId_].ticketAmount-raffles[raffleId_].sold)>ticketAmount_,"not enough tickets available");
        require(msg.value>=(raffles[raffleId_].ticketPrice*ticketAmount_),"insufficient fund");
        uint256 taxAmount = msg.value * ((10000*ticketTax)/1000000);
        (bool success, ) = taxWallet.call{value: taxAmount}("");
        require(success, "Transfer failed.");
        for(uint256 i=0;i<ticketAmount_;i++){
            raffles[raffleId_].tickets.push(msg.sender);
        }
        raffles[raffleId_].sold+=ticketAmount_;
          mint(msg.sender, raffleId_, ticketAmount_, "");
        //Emit buy success   
    }

    function getRafflesByOwner(address addr_) public view returns(uint256 [] memory){
        return rafflesByOwner[addr_];
    }


   function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        internal
    {
        _mint(account, id, amount, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function calculateAllWinner() public onlyOwner {
        //call VRF randomizer
        uint256 currentTime = block.timestamp;
        for(uint256 i=0;i<raffles.length;i++){
            if(raffles[i].endDate>currentTime && raffles[i].isActive){
                //getWinner(raffles[i].id);
                //raffles[raffles[i].id].winner = winner_;
                raffles[raffles[i].id].isActive = false;
            }
        }
        //Emit Raffle complete
    }

    function createRaffle(
    bool isNFT_, 
    string memory name_,uint chainId_,
    uint256 token_, 
    address contractAddress_, 
    uint256 startDate_, 
    uint256 endDate_,
    uint256 treshold_,
    uint256 ticketPrice_,
    uint256 ticketAmount_) public whenNotPaused {
        Raffle memory r ;
        r.id=raffles.length;
        raffles.push(r);
        raffles[r.id].name=name_;
        raffles[r.id].isNFT=isNFT_;
        raffles[r.id].chainId=chainId_;
        raffles[r.id].tokenId=token_;
        raffles[r.id].contractAddress=contractAddress_;
        raffles[r.id].rewardAmount=token_;
        raffles[r.id].raffleOwner=msg.sender;
        raffles[r.id].startDate=startDate_;
        raffles[r.id].endDate=endDate_;
        raffles[r.id].treshold=treshold_ * 1 gwei;
        raffles[r.id].ticketPrice=ticketPrice_ * 1 gwei;
        raffles[r.id].ticketAmount=ticketAmount_;
        raffles[r.id].sold=0;
        raffles[r.id].isCancelled=false; //once cancelled, cannot be re-activated
        raffles[r.id].isActive=false; //will be activated after asset has been staked
        raffleIndex[r.id]=r;
    }

    function activateRaffle(uint256 raffleId_) public onlyOwner whenNotPaused{
        raffles[raffleId_].isActive=true;
    }

    function cancelRaffle(uint256 raffleId_) public nonReentrant {
        require(msg.sender==raffles[raffleId_].raffleOwner,"must be raffle owner");
        raffles[raffleId_].isCancelled=true;
        raffles[raffleId_].isActive=false;
        uint256 refundableAmount = raffles[raffleId_].ticketPrice * ((10000*(100-ticketTax))/1000000);
        for(uint256 i=0;i<raffles[raffleId_].tickets.length;i++){
            refundables[raffles[raffleId_].tickets[i]]+=refundableAmount;
        }
    }

    function claimRefund() public nonReentrant {
        require(refundables[msg.sender]>0,"nothing to claim");
        (bool success, ) = msg.sender.call{value: refundables[msg.sender]}("");
        require(success, "Transfer failed.");
        refundables[msg.sender]=0;
    }


    function getRaffle(uint256 raffleId_) public view returns (Raffle memory) {
        return raffleIndex[raffleId_];

    }
    function getAllRaffles() public view returns(Raffle [] memory ) {
        return raffles;
    }


}