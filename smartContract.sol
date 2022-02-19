// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract AdvertisementContract is ERC721Enumerable, Ownable {

    using SafeMath for uint256;
    using Counters for Counters.Counter;
    string private baseTokenURI;
    uint private basePrice = 10;
    uint private constant commission = 10;
    address payable private owner_;
    Counters.Counter private _tokenIds;

    uint private constant baseNumberNFT = 10;
    struct advertisingSpace {
        uint price;
        uint basePrice;
        uint durationInSeconds;
        string domain;
        string name;
        address payable owner;
        uint NFTid;
        uint purchaseTime;
        string html;
        uint height;
        uint length;
    }

    advertisingSpace[] advertisingSpaces;

    constructor(string memory baseURI) ERC721("NFT Collectible", "NFTC") onlyOwner {
        setBaseURI(baseURI);
        owner_ = payable(msg.sender);
        for (uint i = 0; i < baseNumberNFT; i++) {
          _mintSingleNFT();
          advertisingSpace memory oneSpace = advertisingSpace(
            {
                price: basePrice, 
                durationInSeconds: 0, 
                domain: "google", 
                name: "empty space", 
                owner: owner_, 
                NFTid: _tokenIds.current(),
                purchaseTime: block.timestamp,
                html: "",
                basePrice: basePrice,
                height: 200,
                length: 300
            });
          advertisingSpaces.push(oneSpace);
        }
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function _mintSingleNFT() private {
      uint newTokenID = _tokenIds.current();
      _safeMint(msg.sender, newTokenID);
      _tokenIds.increment();
    }

    function getAllNFT() external view returns(advertisingSpace[] memory) {
        return advertisingSpaces;
    }

    function getPriceForAdv(uint NFTid) public view returns(uint price) {
        uint numberInArr = _getNumberInArrByNFTid(NFTid);
        advertisingSpace storage advertisement = advertisingSpaces[numberInArr];
        if (block.timestamp > (advertisement.purchaseTime + advertisement.durationInSeconds)) {
            return advertisement.basePrice;
        }
        uint withoutCommission = (advertisement.price - advertisement.basePrice) *(1 - (block.timestamp - advertisement.purchaseTime) / advertisement.durationInSeconds) + advertisement.basePrice;
        return withoutCommission * (1 + commission / 100);
    }

    function _getPriceForAdvBySpace(advertisingSpace memory advertisement) private view returns(uint price) {
        if (block.timestamp > (advertisement.purchaseTime + advertisement.durationInSeconds)) {
            return advertisement.basePrice;
        }
        uint withoutCommission = (advertisement.price - advertisement.basePrice) *(1 - (block.timestamp - advertisement.purchaseTime) / advertisement.durationInSeconds) + advertisement.basePrice;
        return withoutCommission * (1 + commission / 100);
    }

    function buyAdvertisementSpace(uint NFTid, uint price, uint durationInSeconds) external payable{
        uint numberInArr = _getNumberInArrByNFTid(NFTid);
        advertisingSpace storage advertisement = advertisingSpaces[numberInArr];
        require(price >= _getPriceForAdvBySpace(advertisement), "Price is not correct");
        require(msg.value >= price, "Ether value sent is not correct");
        owner_.transfer(msg.value);
        if (block.timestamp < (advertisement.purchaseTime + advertisement.durationInSeconds)) {
            returnMoney(advertisement);
        }
        advertisement.price = price;
        advertisement.durationInSeconds = durationInSeconds;
        advertisement.owner = payable (msg.sender);
        advertisement.purchaseTime = block.timestamp;
    }

    function _getNumberInArrByNFTid(uint NFTid) internal view returns(uint numberInArr){
        for (uint i = 0; i < advertisingSpaces.length; i++) {
            if (advertisingSpaces[i].NFTid == NFTid) {
                return i;
            }
        }
        revert("No NFT with such id");
    }

    function returnMoney(advertisingSpace memory advertisement) private {
        uint moneyForReturn = (advertisement.price - advertisement.basePrice) *(1 - (block.timestamp - advertisement.purchaseTime) / advertisement.durationInSeconds);
        advertisement.owner.transfer(moneyForReturn);
    }

    function removeAdvFromUser(uint NFTid) external {
        uint numberInArr = _getNumberInArrByNFTid(NFTid);
        advertisingSpace storage advertisement = advertisingSpaces[uint(numberInArr)];
        advertisement.owner = owner_;
        advertisement.name = "empty space";
        advertisement.html = "";
    }

    function setHtml(uint NFTid, string memory html) external {
        uint numberInArr = _getNumberInArrByNFTid(NFTid);
        advertisingSpace storage advertisement = advertisingSpaces[uint(numberInArr)];
        require(advertisement.owner == msg.sender, "User does not own this NFT");
        advertisement.html = html;
    }

    function getHtml(uint NFTid) external view returns(string memory html) {
        uint numberInArr = _getNumberInArrByNFTid(NFTid);
        return advertisingSpaces[uint(numberInArr)].html;
    }

    function getXY(uint NFTid) external view returns(uint x, uint y){
        uint numberInArr = _getNumberInArrByNFTid(NFTid);
        return (advertisingSpaces[uint(numberInArr)].length, advertisingSpaces[uint(numberInArr)].height);
    }

    function getBalance() external view returns(uint balance) {
        return owner_.balance;
    }

    function addAdvSpace(uint basePriceAdv, uint durationInSeconds, string memory domain, uint height, uint length) external {
        advertisingSpace memory oneSpace = advertisingSpace(
            {
                price: basePriceAdv, 
                durationInSeconds: durationInSeconds, 
                domain: domain, 
                name: "empty space", 
                owner: payable(msg.sender), 
                NFTid: _tokenIds.current(),
                purchaseTime: block.timestamp,
                html: "",
                basePrice: basePriceAdv,
                height: height,
                length: length
            });
          advertisingSpaces.push(oneSpace);
    }
}