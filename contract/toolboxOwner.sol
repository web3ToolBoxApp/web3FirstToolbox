// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract ToolBoxOwner is ERC721, ERC721Enumerable,ERC721Burnable{
    //three type of nft
   
    uint public constant originOwnerID = 0;
    uint public constant earlyOwnerID = 1;
    uint public constant yearOwnerID = 2;

    uint public constant originOwnerCap = 100;
    uint public constant earlyOwnerCap = 500;

    
    /** record the nft is which type 
        key:tokenId
        value == 0 originOwner,
        value == 1 earlyOwner
        value == 2 yearOwner **/
    mapping (uint => uint) private _typeInfo;
    function getTokenType(uint tokenId) public view returns(uint typeID){
        typeID = _typeInfo[tokenId];
    }

    /** record the three types of nft amount 
        key:typeId
        key == 0 originOwner,
        key == 1 earlyOwner
        key == 2 yearOwner 
        value number**/
    mapping (uint => uint) private _typeCurentAmount;
    function getTypeCurentAmount(uint typeID) public view returns(uint amount){
        amount = _typeCurentAmount[typeID];
    }

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    /** yearOwner have this info 
        key = tokenId
        value = timeStamp **/
    mapping (uint => uint) private _expiredTimeInfo;
    function getExpiredTime(uint tokenId) public view returns(uint time){
        time = _expiredTimeInfo[tokenId];
    }

    /** record NFT obtain time
        key = nft obtain address
        key = nft id
        value = timeStamp
        **/
    
    mapping (address => mapping (uint => uint)) private _nftObtainTimeInfo;
    function getNftObtainTime(address owner,uint tokenId) public view returns(uint time){
        time = _nftObtainTimeInfo[owner][tokenId];
    }
    address public manager;
    modifier onlyManager{
        require(msg.sender == manager,"not manager");
        _;
    }

    address public saleContractAddress;
    function setSaleContractAddress(address _saleContractAddress) public onlyManager{
        saleContractAddress = _saleContractAddress;
    }
    modifier onlySaleContract{
        require(msg.sender == saleContractAddress,"not SaleContract");
        _;
    }

    constructor() ERC721("ToolBoxOwner", "TBO") {
        manager = msg.sender;
    }

    function safeMint(address to,uint typeID) public onlySaleContract {
        require(typeID < 3,"don't have this type");
        if (typeID == originOwnerID){
            require(_typeCurentAmount[typeID] < originOwnerCap,"achieve cap");
        }else if (typeID == earlyOwnerID){
            require(_typeCurentAmount[typeID] < earlyOwnerID,"achieve cap");
        }

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _typeInfo[tokenId] = typeID;

        if (typeID == yearOwnerID){
            //a year time = 365 * 24 * 60 * 60 = 31536000
            _expiredTimeInfo[tokenId] = block.timestamp + 31536000;
        }
        _typeCurentAmount[typeID] += 1;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721)
    {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
        _nftObtainTimeInfo[to][tokenId] = block.timestamp;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    function burn(uint256[] calldata tokenIds) public onlyManager{
       for (uint i = 0;i<tokenIds.length;++i){
           uint tokenId = tokenIds[i];
           burn(tokenId);
       }       
    }
    function burn(uint256 tokenId) public override(ERC721Burnable) onlyManager{
        uint curTime = block.timestamp;
        if(_typeInfo[tokenId] == yearOwnerID && curTime > _expiredTimeInfo[tokenId])
        {
            _burn(tokenId);
        }
    }
    
}
