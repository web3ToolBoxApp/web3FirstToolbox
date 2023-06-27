// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./toolBoxOwner.sol";
import "./shareDividend.sol";

// This contract represents a tool sale contract where users can buy tools using a specific token.
// It also includes functionality for loans, dividends, and NFT minting.
interface iW3ft is IERC20Metadata{
    function mint(address to, uint256 amount) external;
    function mint(address[]calldata to, uint256[]calldata amount) external;
    function burn(uint256 amount) external;
    function transferOwnership(address newOwner) external;
}

// This contract represents a tool sale contract where users can buy tools using a specific token.
// It also includes functionality for loans, dividends, and NFT minting.
contract ToolSale is Ownable{
    iW3ft token;// comunity token w3ft
    mapping (address => bool) public operators; //operator can to issue tokens to multiple addresses
    function setOperator(address who,bool canOperator) public onlyOwner{
        operators[who] = canOperator;
    }
    modifier onlyOperator{
        require(operators[msg.sender],"not operator");
        _;
    }
    mapping (address => bool) public isLoan; //record address loan w3ft or not
    /** record address withdraw the reward issue by operator 
        key: merkle tree proof match with the user address
        value: true or false
    **/
    mapping (bytes32 => bool) public isWithdraw;

    //key:invitee value:inviter,record the inviter of user divide the profit to inviter
    mapping (address => address) public inviteInfo;

    //record the nft of toolbox,which will impact the share of profit
    address public nftAddress;
    ToolBoxOwner public nft;// NFT contract instance
    // Sets the address of the NFT contract
    function setNft(address _nftAddress) public onlyOwner{
        nftAddress = _nftAddress;
        nft = ToolBoxOwner(nftAddress);
    }

    ShareDividend public share;// ShareDividend contract instance
    // Sets the address of the ShareDividend contract
    function setShare(address shareContractAddress) public  onlyOwner{
        share = ShareDividend(shareContractAddress);
    }
    
    bytes32 public loanRoot;// Root hash of the merkle tree for loans
    bytes32 public withdrawRoot;// Root hash of the merkle tree for withdraw the reward issue by operator 

    // Event emitted when the loan root is changed
    event loanRootChange(bytes32 originRoot,bytes32 newRoot);
    // Sets the new loan root hash after operator approve user loan w3ft 
    function setLoanRoot(bytes32 _loanRoot) public onlyOperator{
        emit loanRootChange(loanRoot,_loanRoot);
        loanRoot = _loanRoot;
    }
    // Event emitted when the withdrawal root is changed
    event withdrawRootChange(bytes32 originRoot,bytes32 newRoot);
    // Sets the new withdrawal root hash after operator issue user the w3ft rewards
    function setWithdrawRoot(bytes32 _withdrawRoot) public onlyOperator{
        emit withdrawRootChange(withdrawRoot,_withdrawRoot);
        withdrawRoot = _withdrawRoot;
    }
    // Each address only an loan for 500k w3ft
    uint constant loanAmount = 50  * 10 ** 22;

    constructor(address w3ftAddress){
        token = iW3ft(w3ftAddress);
        operators[msg.sender] = true;
    }

    //typeId == 0  buy with BNB,typeId == 1 buy with w3ft
    event buySuccess(address sender,uint itemId,uint amount,uint typeId);
    //buy tool through w3ft
    function buyTool(uint w3ftAmount,uint itemId) public{
        
        token.transferFrom(msg.sender,address(this),w3ftAmount);
        token.burn(w3ftAmount);
        emit buySuccess(msg.sender,itemId,w3ftAmount,1);
    }
    //buy tool through w3ft
    function buyTool(uint itemId,address inviter) public payable{ 
        //first buy add inviter,once add can not change
        if (inviteInfo[msg.sender] == address(0)){
            require(inviter != msg.sender,"inviter can't be yourself");
            inviteInfo[msg.sender] = inviter;            
        }
        _divideShare();
        emit buySuccess(msg.sender,itemId,msg.value,0);
    }

    event shareProfit(address invitee,address inviter,uint amountToInviter,
                    uint amountToShareContract,uint amountToTeam);
    // Internal function to divide the profits and distribute them among inviters, the share contract, and the team
    function _divideShare() internal {
        uint value = msg.value;
        address _inviter = inviteInfo[msg.sender];
        uint amountToInviter = 0;

        // Calculate the amount to be shared with the inviter
        if (_inviter != address(0)) {
            // If the inviter does not own any NFT, they receive 20% of the tool sell
            if (nft.balanceOf(_inviter) == 0) {
                amountToInviter = value * 20 / 100;
            } else {
                // If the inviter owns an NFT, they receive 40% of the tool sell
                amountToInviter = value * 40 / 100;
            }
            payable(_inviter).transfer(amountToInviter);
        }

        // Share 30% of the value with the share contract
        uint amountToShareContract = value * 30 / 100;
        share.receiveShare{value: amountToShareContract}();

        // The remaining amount goes to the team
        uint amountToTeam = value - amountToInviter - amountToShareContract;
        payable(owner()).transfer(amountToTeam);

        emit shareProfit(msg.sender, _inviter, amountToInviter, amountToShareContract, amountToTeam);
    }

    
    // Event emitted when profits are shared
    event mintNftEvent(address who,uint typeID);
    
    // Function to mint an NFT
    function mintNft(uint typeID, address inviter) public payable {
        // First buy adds the inviter, once added it cannot be changed
        if (inviteInfo[msg.sender] == address(0)) {
            require(inviter != msg.sender,"inviter can't be yourself");
            inviteInfo[msg.sender] = inviter;
        }

        uint value = msg.value;

        // Mint the NFT based on the specified type and value
        if (typeID == nft.genesisOwnerID()) {
            require(value == 0.05 ether, "value is not correct");
            nft.safeMint(msg.sender, typeID);
            payable(owner()).transfer(value);
        } else if (typeID == nft.alphaOwnerID()) {
            require(value == 0.01 ether, "value is not correct");
            nft.safeMint(msg.sender, typeID);
            payable(owner()).transfer(value);
        } 
        // The year owner nft divide the profits and distribute them among inviters, the share contract, and the team
        else if (typeID == nft.yearOwnerID()) {
            require(value == 0.01 ether, "value is not correct");
            nft.safeMint(msg.sender, typeID);
            _divideShare();
        }

        emit mintNftEvent(msg.sender, typeID);
    }
    
    // Event emitted when a loan is taken
    event Loan(address who);

    // Function to take a loan based on the merkle proof
    function loan(bytes32[] calldata proof) public {
        require(!isLoan[msg.sender], "please pay back loan");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verifyCalldata(proof, loanRoot, leaf), "Not qualified");
        token.mint(msg.sender, loanAmount);
        isLoan[msg.sender] = true;

        emit Loan(msg.sender);
    }

    // Event emitted when a loan is paid back
    event PayBack(address who);

    // Function to pay back a loan
    function payBack() public {
        require(token.balanceOf(msg.sender) >= loanAmount);
        token.transferFrom(msg.sender, address(this), loanAmount);
        isLoan[msg.sender] = false;

        emit PayBack(msg.sender);
    }

    // Event emitted when a withdrawal is made
    event Withdraw(address who, uint256 amount, uint256 timeStamp);

    // Function to withdraw an amount based on the merkle proof
    function withdraw(bytes32[] calldata proof, uint256 amount, uint256 timeStamp) public {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount, timeStamp));
        require(!isWithdraw[leaf], "Already withdraw");
        require(MerkleProof.verifyCalldata(proof, withdrawRoot,leaf), "Not qualified");
        token.mint(msg.sender, amount);
        isWithdraw[leaf] = true;

        emit Withdraw(msg.sender, amount, timeStamp);
    }

    // Function to issue tokens to multiple addresses
    function issueToken(address[] calldata to, uint256[] calldata amount) public onlyOwner {
        token.mint(to, amount);
    }

    // Function to transfer token ownership to a new owner
    function transferTokenOwnerShip(address to) public onlyOwner {
        token.transferOwnership(to);
    }
}