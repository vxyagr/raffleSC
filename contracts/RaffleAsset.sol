// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RaffleAsset is Pausable, Ownable {
    using SafeMath for address;
    using SafeMath for uint256;
    struct NFTAsset {
        string id;
        uint256 tokenId;
        address contractAddress;
        address assetOwner;
        bool isStaked;
        uint256 releaseDate;
        uint256 raffleId;
        bool raffleWon;
        bool claimed;
    }

     struct CoinAsset {
        uint256 id;
        uint256 coinAmount;
        address contractAddress;
        address assetOwner;
        bool isStaked;
        uint256 releaseDate;
        uint256 raffleId;
        bool raffleWon;
        bool claimed;
    }

    struct CryptoAsset {
        uint256 id;
        bool isNFT;
        uint256 token;
        address contractAddress;
        address assetOwner;
        bool isStaked;
        uint256 releaseDate;
        uint256 raffleId;
        bool raffleWon;
        bool claimed;

    }

    CryptoAsset [] assets;
    //CoinAsset [] coins;
    mapping(uint256=>CryptoAsset) assetStakingIndex; //raffleId - stakingId
    //mapping(uint256=>CoinAsset) coinStakingIndex; //raffleId - stakingId
    mapping(address=>CryptoAsset[]) nftAssetByAddress;
    //mapping(address=>CoinAsset[]) coinAssetByAddress;
    
    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function stakeAsset(bool isNFT_, address addr_, uint256 token_, uint256 raffleId_) public{
        require(isERC721(addr_),"not an NFT asset");
        if(isNFT_){
            IERC721 nftContract_ = IERC721(addr_);
            require(nftContract_.ownerOf(token_)==msg.sender,"not the owner");
            require(nftContract_.getApproved(token_)==address(this), "not approved to transfer");
            nftContract_.transferFrom(msg.sender, address(this), token_);
        }else{

        }
        CryptoAsset memory asset_;
        asset_.assetOwner = address(this);
        asset_.isNFT=isNFT_;
        asset_.contractAddress = addr_;
        asset_.token = token_;
        asset_.raffleId = raffleId_;
        asset_.isStaked=true;
        asset_.raffleWon=false;
        asset_.claimed=false;
        assets.push(asset_);
        //nftAssetByAddress[msg.sender].push(nftAsset_);
    }

    function isStaked(uint256 raffleId_) public view returns(bool){
        return assetStakingIndex[raffleId_].isStaked;
    }

    function setWinner(uint256 raffleId_, address addr_)public onlyOwner{
        assetStakingIndex[raffleId_].assetOwner=addr_;
        assetStakingIndex[raffleId_].raffleWon=true;
    }
 

    function returnAsset(uint256 raffleId_) public onlyOwner{
         /*IERC721 nftContract_ = IERC721(nftStakingIndex[raffleId_].contractAddress);
         nftContract_.transferFrom(address(this), nftStakingIndex[raffleId_].assetOwner,nftStakingIndex[raffleId_].tokenId );
         nftStakingIndex[raffleId_].isStaked=false;
         nftStakingIndex[raffleId_].claimed=true; */
    }

    function claimAsset(uint256 raffleId_) public {
        //require()
        require(assetStakingIndex[raffleId_].raffleWon || assetStakingIndex[raffleId_].releaseDate>block.timestamp,"");
        require(assetStakingIndex[raffleId_].assetOwner==msg.sender,"not the owner");
        if(assetStakingIndex[raffleId_].isNFT){
            IERC721 nftContract_ = IERC721(assetStakingIndex[raffleId_].contractAddress);
            nftContract_.transferFrom(address(this), assetStakingIndex[raffleId_].assetOwner,assetStakingIndex[raffleId_].token );
        }else{
            IERC20 coinContract_ = IERC20(assetStakingIndex[raffleId_].contractAddress);
            coinContract_.transferFrom(address(this), assetStakingIndex[raffleId_].assetOwner,assetStakingIndex[raffleId_].token );
        }
        
        assetStakingIndex[raffleId_].isStaked=false;
        assetStakingIndex[raffleId_].claimed=true;
    }


    function unstakeNFTAsset() public {

    }

    function unstakeCoinAsset() public {

    }

    function isERC721(address addr_)public view returns (bool) {
        IERC165 theContract = IERC165(addr_);
        bytes4 interfaceId = 0x80ac58cd; // ERC20 interface ID
        return theContract.supportsInterface(interfaceId);
    }

    function isERC20(address addr_)public view returns (bool) {
        IERC165 contractToCheck = IERC165(addr_);
        bytes4 interfaceId = 0x01ffc9a7; // ERC20 interface ID
        return contractToCheck.supportsInterface(interfaceId);
    }


}