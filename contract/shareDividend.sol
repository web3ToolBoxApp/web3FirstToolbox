// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IToolBoxOwner is IERC721Enumerable{
    function getTokenType(uint tokenId) external view returns(uint typeID);
    function getExpiredTime(uint tokenId) external view returns(uint time);
    function getNftObtainTime(address owner,uint tokenId) external view returns(uint time);
}

contract ShareDividend is Ownable{
    //one month = 30 * 24 * 60 * 60 = 2592000
    uint public constant period  = 2592000;
    uint public startTime;
    //period time = startTime + period * curRound
    uint public curRound;
   

    //key : round value : value
    mapping (uint => uint) public roundProfitInfo;
    //key : round value : nft number
    mapping (uint => uint) public roundShareNum;
    //      timestamp         nftOwner   withdraw or not
    mapping (uint => mapping (address => bool)) public withdrawState;
    // after three month empty 3 month ago profit add to current month
    mapping (uint => bool) private emptyRoundProfit;

    function setStartTime(uint time) public onlyOwner{
        startTime = time;
    }
    
    IToolBoxOwner nft;
    function setNft(address nftAddress) public onlyOwner{
        nft = IToolBoxOwner(nftAddress);
    }
    
    function emptyProfit(uint round) public onlyOwner{
        _emptyProfit(round);
    }

    function _emptyProfit(uint round) internal {
        require(!emptyRoundProfit[round],"already empty this round profit");
        roundProfitInfo[round + 3] += roundProfitInfo[round];
        roundProfitInfo[round] = 0;
        emptyRoundProfit[round] = true;
    }

    function _recordProfit() internal {
        uint curtime = block.timestamp;
        curRound = (curtime - startTime) / period;
        uint curPeriod = startTime + curRound * period;
        if (curPeriod > 3 && !emptyRoundProfit[curPeriod - 3]){
            _emptyProfit(curPeriod - 3);
        }
        roundProfitInfo[curRound] += msg.value;
        roundShareNum[curRound] = nft.totalSupply();
    }

    
    function  withdrawShare(uint round) public{
        uint withdrawTime = startTime + round * period;
        address ownerAddress = msg.sender;
        require(!withdrawState[round][ownerAddress],"already withdraw");
        uint balance = nft.balanceOf(ownerAddress);
        require(balance > 0,"dont have right to withdraw share");
        uint roundProfit = roundProfitInfo[round];
        require(roundProfit > 0,"curent round dont have profit");
        uint avaliableShare = 0;
        for (uint i=0;i<balance;++i){
            uint tokenId = nft.tokenOfOwnerByIndex(ownerAddress,i);
            uint nftObtainTime = nft.getNftObtainTime(ownerAddress, tokenId);
            if (withdrawTime > nftObtainTime && (withdrawTime - nftObtainTime) >= period)
            {
                avaliableShare += 1;
            }
        }
        uint shareAmount = avaliableShare * roundProfit / roundShareNum[round];
        payable(ownerAddress).transfer(shareAmount);
    }
    function receiveShare() public payable {
        _recordProfit();
    }
}