// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./toolBoxOwner.sol";
import "./shareDividend.sol";

interface iW3ft is IERC20Metadata{
    function mint(address to, uint256 amount) external;
    function mint(address[]calldata to, uint256[]calldata amount) external;
    function burn(uint256 amount) external;
    function transferOwnership(address newOwner) external;
}

contract ToolSale is Ownable{
    iW3ft token;
    mapping (address => bool) public operators; 
    function setOperator(address who,bool canOperator) public onlyOwner{
        operators[who] = canOperator;
    }
    modifier onlyOperator{
        require(operators[msg.sender],"not operator");
        _;
    }
    mapping (address => bool) public isLoan; 
    mapping (bytes32 => bool) public isWithdraw;

    //key:invitee value:inviter
    mapping (address => address) public inviteInfo;
    address public nftAddress;
    ToolBoxOwner public nft;
    function setNft(address _nftAddress) public onlyOwner{
        nftAddress = _nftAddress;
        nft = ToolBoxOwner(nftAddress);
    }

    //shareContract
    ShareDividend public share;
    function setShare(address shareContractAddress) public  onlyOwner{
        share = ShareDividend(shareContractAddress);
    }
    
    bytes32 public loanRoot;
    bytes32 public withdrawRoot;
    event loanRootChange(bytes32 originRoot,bytes32 newRoot);
    function setLoanRoot(bytes32 _loanRoot) public onlyOwner{
        emit loanRootChange(loanRoot,_loanRoot);
        loanRoot = _loanRoot;
    }
    event withdrawRootChange(bytes32 originRoot,bytes32 newRoot);
    function setWithdrawRoot(bytes32 _withdrawRoot) public onlyOwner{
        emit withdrawRootChange(withdrawRoot,_withdrawRoot);
        withdrawRoot = _withdrawRoot;
    }

    uint constant loanAmount = 50  * 10 ** 22;

    constructor(address w3ftAddress){
        token = iW3ft(w3ftAddress);
        operators[msg.sender] = true;
    }
    //typeId == 0  buy with BNB,typeId == 1 buy with w3ft
    event buySuccess(address sender,uint itemId,uint amount,uint typeId);
    function buyTool(uint w3ftAmount,uint itemId) public{
        
        token.transferFrom(msg.sender,address(this),w3ftAmount);
        token.burn(w3ftAmount);
        emit buySuccess(msg.sender,itemId,w3ftAmount,1);
    }
    event shareProfit(address invitee,address inviter,uint amountToInviter,
                    uint amountToShareContract,uint amountToTeam);
    function _divideShare() internal{
        //caculate inviter share
        uint value = msg.value;
        address _inviter = inviteInfo[msg.sender];
        uint amountToInviter = 0;
        if (_inviter != address(0)){
            //own nft can share 40% of tool sell
            if (nft.balanceOf(_inviter) == 0){
                amountToInviter = value * 20 / 100;
            }else{
                amountToInviter = value * 40 / 100;
            }
            payable (_inviter).transfer(amountToInviter);
        }
        uint amountToShareContract = value * 30 / 100;
        share.receiveShare{value:amountToShareContract}();
        uint amountToTeam = value - amountToInviter - amountToShareContract;
        payable(owner()).transfer(amountToTeam);
        emit shareProfit(msg.sender, _inviter, amountToInviter, amountToShareContract, amountToTeam);
    }

    function buyTool(uint itemId,address inviter) public payable{ 
        //first buy add inviter,once add can not change
        if (inviteInfo[msg.sender] == address(0)){
            inviteInfo[msg.sender] = inviter;
        }
        _divideShare();
        emit buySuccess(msg.sender,itemId,msg.value,0);
    }

    event mintNftEvent(address who,uint typeID);
    function mintNft(uint typeID,address inviter) public payable {
        //first buy add inviter,once add can not change
        if (inviteInfo[msg.sender] == address(0)){
            inviteInfo[msg.sender] = inviter;
        }
        uint value = msg.value;
        if(typeID == nft.originOwnerID()){
            require(value == 5 ether,"value is not correct");
            nft.safeMint(msg.sender,typeID);
            payable(owner()).transfer(value);
        }else if(typeID == nft.earlyOwnerID()){
            require(value == 1 ether,"value is not correct");
            nft.safeMint(msg.sender,typeID);
            payable(owner()).transfer(value);
        }else if(typeID == nft.yearOwnerID()){
            require(value == 1 ether,"value is not correct");
            nft.safeMint(msg.sender,typeID);
            _divideShare();
        }
        emit mintNftEvent(msg.sender,typeID);
    }
    
    

    event Loan(address who);
    function loan(bytes32[] calldata proof) public{
        require(!isLoan[msg.sender],"please pay back loan");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verifyCalldata(proof,leaf,loanRoot),"Not qualified");
        token.mint(msg.sender,loanAmount);
        isLoan[msg.sender] = true;
        
        emit Loan(msg.sender);
    }
    event PayBack(address who);
    function payBack() public{
        require(token.balanceOf(msg.sender) >= loanAmount);
        token.transferFrom(msg.sender,address(this),loanAmount);
        isLoan[msg.sender] = false;
        emit PayBack(msg.sender);
    }
    event Withdraw(address who,uint256 amount,uint256 timeStamp);
    function withdraw(bytes32[] calldata proof,uint256 amount,uint timeStamp) public{
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender,amount,timeStamp));
        require(!isWithdraw[leaf],"Already withdraw");
        require(MerkleProof.verifyCalldata(proof,leaf,withdrawRoot),"Not qualified");
        token.mint(msg.sender,amount);
        isWithdraw[leaf] = true;
        emit Withdraw(msg.sender,amount,timeStamp);
    }

    function issueToken(address[]calldata to, uint256[]calldata amount) public onlyOwner{
        token.mint(to,amount);
    }
    function transferTokenOwnerShip(address to) public onlyOwner{
        token.transferOwnership(to);
    }
}