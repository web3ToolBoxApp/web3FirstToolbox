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
    // One month = 30 * 24 * 60 * 60 = 2592000 seconds
    uint public constant period = 2592000;
    uint public startTime;
    uint public curRound;

    // Mapping to store the profit for each round
    mapping (uint => uint) public roundProfitInfo;

    // Mapping to store the number of shares for each round
    mapping (uint => uint) public roundShareNum;

    // Mapping to track the withdrawal state of each round for each owner
    mapping (uint => mapping (address => bool)) public withdrawState;

    // Mapping to track if the profit for a round has been emptied to the next round
    mapping (uint => bool) private emptyRoundProfit;

    /**
    * @dev Sets the start time for dividend calculation.
    * @param time The start time.
    */
    function setStartTime(uint time) public onlyOwner {
        startTime = time;
    }

    IToolBoxOwner nft;

    /**
    * @dev Sets the address of the NFT contract.
    * @param nftAddress The address of the NFT contract.
    */
    function setNft(address nftAddress) public onlyOwner {
        nft = IToolBoxOwner(nftAddress);
    }

    /**
    * @dev Empties the profit from a previous round to the current round.
    * @param round The round to empty the profit from.
    */
    function emptyProfit(uint round) public onlyOwner {
        _emptyProfit(round);
    }

    function _emptyProfit(uint round) internal {
        require(!emptyRoundProfit[round], "Already emptied this round's profit");
        roundProfitInfo[round + 3] += roundProfitInfo[round];
        roundProfitInfo[round] = 0;
        emptyRoundProfit[round] = true;
    }

    function _recordProfit() internal {
        uint curtime = block.timestamp;
        curRound = (curtime - startTime) / period;
        if (curRound > 3 && !emptyRoundProfit[curRound - 3]) {
            _emptyProfit(curRound - 3);
        }
        roundProfitInfo[curRound] += msg.value;
        roundShareNum[curRound] = nft.totalSupply();
    }

    /**
    * @dev get specific share of nft owner for a specific round.
    * @param owner The owner of the NFT.
    * @param round The round to withdraw the share from.
    */
    function getOwnerShare(address owner, uint round) public view returns(uint) {
        uint balance = nft.balanceOf(owner);
        uint avaliableShare = 0;
        for (uint i = 0; i < balance; ++i) {
            uint tokenId = nft.tokenOfOwnerByIndex(owner, i);
            uint nftObtainTime = nft.getNftObtainTime(owner, tokenId);
            if (startTime + round * period > nftObtainTime && (startTime + round * period - nftObtainTime) >= period) {
                avaliableShare += 1;
            }
        }
        return avaliableShare * roundProfitInfo[round] / roundShareNum[round];
    }

    /**
    * @dev Event emitted when an owner withdraws their share.
    * @param who The address of the owner.
    * @param avaliableShare The number of available shares.
    * @param shareAmount The amount of share to withdraw.
    */
    event withdrawShareEvent(address who, uint avaliableShare, uint shareAmount);

    /**
    * @dev Withdraws the share for a specific round.
    * @param round The round to withdraw the share from.
    */
    function withdrawShare(uint round) public {
        uint withdrawTime = startTime + round * period;
        address ownerAddress = msg.sender;
        require(!withdrawState[round][ownerAddress], "Already withdrawn");
        uint balance = nft.balanceOf(ownerAddress);
        require(balance > 0, "Not eligible to withdraw share");
        uint roundProfit = roundProfitInfo[round];
        require(roundProfit > 0, "No profit available for the current round");
        uint avaliableShare = 0;
        for (uint i = 0; i < balance; ++i) {
            uint tokenId = nft.tokenOfOwnerByIndex(ownerAddress, i);
            uint nftObtainTime = nft.getNftObtainTime(ownerAddress, tokenId);
            if (withdrawTime > nftObtainTime && (withdrawTime - nftObtainTime) >= period) {
                avaliableShare += 1;
            }
        }
        uint shareAmount = avaliableShare * roundProfit / roundShareNum[round];
        payable(ownerAddress).transfer(shareAmount);
        withdrawState[round][ownerAddress] = true;
        emit withdrawShareEvent(ownerAddress, avaliableShare, shareAmount);
    }

    /**
    * @dev Function to receive Ether and record the profit for the current round.
    */
    function receiveShare() public payable {
        _recordProfit();
    }

}