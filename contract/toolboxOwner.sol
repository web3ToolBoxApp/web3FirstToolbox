// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract ToolBoxOwner is ERC721, ERC721Enumerable,ERC721Burnable{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    // Three types of NFTs
    uint public constant originOwnerID = 0;
    uint public constant earlyOwnerID = 1;
    uint public constant yearOwnerID = 2;

    // Cap for each type of NFT
    uint public constant originOwnerCap = 100;
    uint public constant earlyOwnerCap = 500;

    // Mapping to record the type of each NFT
    mapping (uint => uint) private _typeInfo;

    /**
    * @dev Returns the type of the token.
    * @param tokenId The token ID.
    * @return typeID The type of the token.
    */
    function getTokenType(uint tokenId) public view returns(uint typeID) {
        typeID = _typeInfo[tokenId];
    }

    // Mapping to record the current amount of each type of NFT
    mapping (uint => uint) private _typeCurentAmount;

    /**
    * @dev Returns the current amount of tokens for the given type.
    * @param typeID The type ID.
    * @return amount The current amount of tokens.
    */
    function getTypeCurentAmount(uint typeID) public view returns(uint amount) {
        amount = _typeCurentAmount[typeID];
    } 

    // Mapping to record the expiration time for yearOwner NFTs
    mapping (uint => uint) private _expiredTimeInfo;

    /**
    * @dev Returns the expiration time for the given token.
    * @param tokenId The token ID.
    * @return time The expiration time for the token.
    */
    function getExpiredTime(uint tokenId) public view returns(uint time) {
        time = _expiredTimeInfo[tokenId];
    }

    // Mapping to record the NFT obtain time for each owner and token ID
    mapping (address => mapping (uint => uint)) private _nftObtainTimeInfo;

    /**
    * @dev Returns the NFT obtain time for the given owner and token ID.
    * @param owner The owner of the NFT.
    * @param tokenId The token ID.
    * @return time The NFT obtain time.
    */
    function getNftObtainTime(address owner, uint tokenId) public view returns(uint time) {
        time = _nftObtainTimeInfo[owner][tokenId];
    }

    address public manager;
    modifier onlyManager {
        require(msg.sender == manager, "Not manager");
        _;
    }

    address public saleContractAddress;

    /**
    * @dev Sets the address of the sale contract.
    * @param _saleContractAddress The address of the sale contract.
    */
    function setSaleContractAddress(address _saleContractAddress) public onlyManager {
        saleContractAddress = _saleContractAddress;
    }

    modifier onlySaleContract {
        require(msg.sender == saleContractAddress, "Not SaleContract");
        _;
    }

    constructor() ERC721("ToolBoxOwner", "TBO") {
        manager = msg.sender;
    }

    /**
    * @dev Safely mints a new NFT to the given address.
    * @param to The address to mint the NFT to.
    * @param typeID The type of the NFT to mint.
    */
    function safeMint(address to, uint typeID) public onlySaleContract {
        require(typeID < 3, "Invalid type");
        if (typeID == originOwnerID) {
            require(_typeCurentAmount[typeID] < originOwnerCap, "Reached cap");
        } else if (typeID == earlyOwnerID) {
            require(_typeCurentAmount[typeID] < earlyOwnerCap, "Reached cap");
        }

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _typeInfo[tokenId] = typeID;

        if (typeID == yearOwnerID) {
            // Set a year time = 365 * 24 * 60 * 60 = 31536000
            _expiredTimeInfo[tokenId] = block.timestamp + 31536000;
        }
        _typeCurentAmount[typeID] += 1;
    }

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

    /**
    * @dev Burns the year nft after expired
    * @param tokenIds The array of token IDs to burn.
    */
    function burn(uint256[] calldata tokenIds) public onlyManager {
        for (uint i = 0; i < tokenIds.length; ++i) {
            uint tokenId = tokenIds[i];
            burn(tokenId);
        }       
    }

    function burn(uint256 tokenId) public override(ERC721Burnable) onlyManager {
        uint curTime = block.timestamp;
        if (_typeInfo[tokenId] == yearOwnerID && curTime > _expiredTimeInfo[tokenId]) {
            _burn(tokenId);
        }
    }

}
