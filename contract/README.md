# 合约综合说明

本文档对三个智能合约进行了综合说明，包括 ToolSale 合约、ToolboxOwner 合约和ShareDividend 合约。

## Tool Sale 合约

Tool Sale 合约是一个用于工具产品销售、NFT 铸造、邀请人分红和销售利润分红的智能合约。该合约还涉及社区积分 W3FT 的借用和奖励发放功能。

### 功能

Tool Sale 合约提供以下功能：

- 工具销售：用户可以使用社区积分 W3FT 或 BNB 购买工具。
- NFT Pass 卡铸造：用户可以使用不同数量的 BNB 铸造不同类型的 NFT Pass 卡，包括 genesisOwner、alphaOwner 和 yearOwner。其中，yearOwner 类型的 NFT 在一年后过期，并进行利润分红。其他类型的 NFT 收入将分配给开发团队。
- 邀请人机制：邀请人在购买人首次购买时绑定，一旦绑定将无法更改。
- 销售利润分红：使用 BNB 购买工具或铸造 yearOwner NFT 时将进行利润分红，分红对象包括购买人的邀请人、NFT 持有人和项目团队。具体分红比例为：邀请人持有 NFT 获得 40% 分红，未持有 NFT 获得 20% 分红；NFT 持有人获得 30% 分红；项目团队获得剩余利润。
- 社区积分 W3FT 的借用和奖励发放：由运营人员审批通过后会给对应地址发放社区积分 W3FT。

## ToolboxOwner 合约

ToolboxOwner 合约是一个社区 NFT 合约，包含三种不同类型的 NFT：genesisOwner、alphaOwner 和 yearOwner。其中，yearOwner 类型的 NFT 在一年后过期，并会被运营人员销毁。
- genesisOwner铸造上限：100
- alphaOwner铸造上限：500
- yearOwner铸造上限：无上限

## ShareDividend 合约

ShareDividend 合约用于记录 NFT 持有人的分红信息。具体规则如下：

- 每月分红一次，根据当前地址持有社区 NFT ToolboxOwner 的数据，获取当月的分红份额。
- 当月获得 NFT 的地址将在下一个月才有分红资格。
- 每过 3 个月，3 个月前未提取分红的月份利润将累积到当前月份。

# 主网合约地址
- ToolSale:https://bscscan.com/address/0x3470593349f0d2b1bC5fcFd00D0Fd27A1F341A0b
- ToolBoxOwner:https://bscscan.com/address/0x35A3Ee538BbaC345B0411A97Fe3ecc614bfDA259
- ShareDividend:https://bscscan.com/address/0x160A2EC60bE0452187e0381001D4BA87ce34975e

# 测试网合约说明

合约已在bsc测试网部署，并且开源，参与测试的小伙伴可以在discord测试反馈频道提出bug,后续将针对bug严重程度给予奖励，为方便测试已对合约作出以下调整

- Mint NFT 所需金额调整为，genesisOwner 0.05 TBNB，alphaOwner 0.01 TBNB, yearOwner 0.01TBNB
- yearOwner NFT 过期时间设置为一天
- 每轮分红设置为一天

合约地址：
- ToolSale:https://testnet.bscscan.com/address/0x6D4561Fe09C553D2031c9394A4446F944EDD9585
- ToolBoxOwner:https://testnet.bscscan.com/address/0x783443f9f41baA86EdA15D4A0A85C0b01e507a60
- ShareDividend:https://testnet.bscscan.com/address/0x9167F3EA78C239641E5C6aCD81e6F16B91f74Ea2

# Tool Sale Contract

这是一个工具销售合约，用户可以使用特定代币购买工具。该合约还包括贷款、股息和非同质化代币（NFT）铸造的功能。

## 合约功能

### 1. 工具销售合约

合约 `ToolSale` 继承自 `Ownable` 合约，并包含以下功能：

- `setOperator(address who, bool canOperator)`：仅合约所有者可调用的函数，用于设置操作员权限，即操作员可以向多个地址发行代币。
- `buyTool(uint w3ftAmount, uint itemId)`：使用指定数量的社区积分W3FT购买工具的函数，通过调用 `token` 合约的转账函数实现。
- `buyTool(uint itemId, address inviter)`：使用以太币购买工具的函数，同时支持推荐人机制，通过调用 `_divideShare` 函数实现。
- `_divideShare()`：内部函数，用于将收益分配给推荐人、股息合约和团队成员。
- `setNft(address _nftAddress)`：仅合约所有者可调用的函数，设置 NFT 合约的地址。
- `setShare(address shareContractAddress)`：仅合约所有者可调用的函数，设置股息合约的地址。
- `mintNft(uint typeID, address inviter)`：铸造 NFT 的函数，根据指定的类型和价值进行铸造，同时支持推荐人机制。
- `setLoanRoot(bytes32 _loanRoot)`：仅操作员可调用的函数，设置贷款根哈希。
- `setWithdrawRoot(bytes32 _withdrawRoot)`：仅操作员可调用的函数，设置奖励提取根哈希。
- `loan(bytes32[] calldata proof)`：根据 Merkle 证明贷款的函数。
- `payBack()`：还款函数。
- `withdraw(bytes32[] calldata proof, uint256 amount, uint256 timeStamp)`：根据 Merkle 证明提取奖励的函数。
- `issueToken(address[] calldata to, uint256[] calldata amount)`：仅合约所有者可调用的函数，向多个地址发行代币。
- `transferTokenOwnerShip(address to)`：仅合约所有者可调用的函数，将代币的所有权转移给新的地址。

### 2. NFT 管理

合约 `ToolSale` 包含以下 NFT 相关功能：

- `nftAddress`：设置 ToolBoxOwner NFT 合约的地址。
- `nft`：设置 ToolBoxOwner NFT 合约的实例。
- `mintNftEvent(address who, uint typeID)`：铸造 NFT 成功时触发的事件。
- `mintNft(uint typeID, address inviter)`：铸造 NFT 的函数，根据指定的类型和价值进行铸造，同时支持推荐人机制。

### 3. 股息分配

合约 `ToolSale` 包含以下股息分配功能：

- `share`：记录股息合约的实例。
- `shareProfit(address invitee, address inviter, uint amountToInviter, uint amountToShareContract, uint amountToTeam)`：收益分配时触发的事件。
- `_divideShare()`：内部函数，用于将收益分配给推荐人、股息合约和团队成员。

### 4. 贷款与奖励提取

合约 `ToolSale` 包含以下贷款与奖励提取功能：

- `isLoan`：记录地址是否获取社区积分W3FT借款。
- `loanRoot`：社区积分W3FT借款根哈希。
- `withdrawRoot`：奖励提取根哈希。
- `Loan(address who)`：社区积分W3FT借款成功时触发的事件。
- `PayBack(address who)`：社区积分W3FT还款成功时触发的事件。
- `Withdraw(address who, uint256 amount, uint256 timeStamp)`：奖励提取成功时触发的事件。
- `setLoanRoot(bytes32 _loanRoot)`：仅操作员可调用的函数，设置社区积分W3FT借款根哈希。
- `setWithdrawRoot(bytes32 _withdrawRoot)`：仅操作员可调用的函数，设置奖励提取根哈希。
- `loan(bytes32[] calldata proof)`：根据 Merkle 证明社区积分W3FT借款的函数。
- `payBack()`：还款函数。
- `withdraw(bytes32[] calldata proof, uint256 amount, uint256 timeStamp)`：根据 Merkle 证明提取奖励的函数。

### 5. 代币发行与所有权转移

合约 `ToolSale` 包含以下代币发行与所有权转移功能：

- `token`：记录代币合约的实例。
- `issueToken(address[] calldata to, uint256[] calldata amount)`：仅合约所有者可调用的函数，向多个地址发行代币。
- `transferTokenOwnerShip(address to)`：仅合约所有者可调用的函数，将代币的所有权转移给新的地址。

### 6. 其他合约引入

合约中还引入了以下合约：

- `IERC20Metadata.sol`：OpenZeppelin 中的 ERC20 代币合约接口。
- `Ownable.sol`：OpenZeppelin 中的拥有者权限管理合约。
- `MerkleProof.sol`：OpenZeppelin 中的 Merkle 树验证合约。
- `IERC721.sol`：OpenZeppelin 中的 ERC721 非同质化代币合约接口。
- `ToolBoxOwner.sol`：自定义的工具箱 NFT 合约，用于管理工具箱的 NFT。
- `ShareDividend.sol`：自定义的股息分配合约，用于处理股息分配。

注意：以上为对代码进行综合分析后的中文说明，具体内容请参考源代码。

# ToolBoxOwner 合约

ToolBoxOwner 合约是一个基于 ERC721 标准的合约，用于管理工具箱的非同质化代币（NFT）。它继承了 OpenZeppelin 的 ERC721、ERC721Enumerable 和 ERC721Burnable 合约。

## 功能

ToolBoxOwner 合约提供以下功能：

- 铸造不同类型的 NFT，包括genesis所有者（genesisOwner）、alpha所有者（alphaOwner）和年度所有者（yearOwner）。
- 设置每种类型 NFT 的铸造上限。
- 记录每个 NFT 的类型、当前数量和到期时间。
- 获取特定 NFT 的类型、当前数量、到期时间和获得时间。
- 设置销售合约的地址。
- 管理员可以烧毁已到期的年度所有者 NFT。

## 数据结构

ToolBoxOwner 合约使用以下映射来存储数据：

- `_typeInfo`：记录每个 NFT 的类型。
- `_typeCurentAmount`：记录每个类型 NFT 的当前数量。
- `_expiredTimeInfo`：记录年度所有者 NFT 的到期时间。
- `_nftObtainTimeInfo`：记录每个所有者和 NFT 的获得时间。

## 函数

ToolBoxOwner 合约包含以下函数：

- `getTokenType(uint tokenId)：返回指定 NFT 的类型。
- `getTypeCurentAmount(uint typeID)：返回指定类型 NFT 的当前数量。
- `getExpiredTime(uint tokenId)：返回指定 yearOwner NFT 的到期时间。
- `getNftObtainTime(address owner, uint tokenId)：返回指定所有者和 NFT 的获得时间。
- `setSaleContractAddress(address _saleContractAddress)：设置销售合约的地址。
- `safeMint(address to, uint typeID)：安全地铸造一个新的 NFT，并分配给指定地址。
- `burn(uint256[] calldata tokenIds)：烧毁多个指定的到期yearOwner NFT。
- `burn(uint256 tokenId)：烧毁指定的到期yearOwner NFT。

## 事件

ToolBoxOwner 合约触发以下事件：

- `Transfer(address from, address to, uint256 tokenId)`：当 NFT 转移所有权时触发的事件。
- `Approval(address owner, address approved, uint256 tokenId)`：当 NFT 所有权被授权给其他地址时触发的事件。
- `ApprovalForAll(address owner, address operator, bool approved)`：当 NFT 所有者授权操作者操作其所有 NFT 时触发的事件。
- `URI(string value, uint256 indexed id)`：当设置 NFT 的元数据 URI 时触发的事件。

## 权限控制

ToolBoxOwner 合约使用以下权限控制修饰符：

- `onlyManager`：限制只有管理员可以调用的函数。
- `onlySaleContract`：限制只有销售合约可以调用的函数。

## 构造函数

ToolBoxOwner 合约的构造函数将合约的部署者设置为管理员。

## 支持的标准

ToolBoxOwner 合约支持 ERC721 和 ERC721Enumerable 标准。

## 注释

合约中的注释提供了对函数和变量的说明，可以作为参考来理解代码的功能和用法。

> 注意：以上为对代码进行综合分析后的中文说明，具体内容请参考源代码。

# ShareDividend 合约

ShareDividend 合约是一个用于分红的合约。

## 功能

ShareDividend 合约提供以下功能：

- 设置分红计算的开始时间。
- 设置与 NFT 合约的地址。
- 将上一轮的利润转移至当前轮。
- 记录每轮的利润和股份数量。
- 允许所有者提取特定轮次的股份。

## 数据结构

ShareDividend 合约使用以下映射来存储数据：

- `roundProfitInfo`：记录每轮的利润。
- `roundShareNum`：记录每轮的股份数量。
- `withdrawState`：跟踪每轮每个所有者的提取状态。
- `emptyRoundProfit`：记录每轮的利润是否已转移至下一轮。

## 函数

ShareDividend 合约包含以下函数：

- `setStartTime(uint time)`：设置分红计算的开始时间。
- `setNft(address nftAddress)`：设置 NFT 合约的地址。
- `emptyProfit(uint round)`：将上三轮的利润转移至当前轮。
- `withdrawShare(uint round)`：提取特定轮次的股份。
- `receiveShare()`：接收以太币并记录当前轮次的利润。
- `getOwnerShare(address owner,uint round)`：获取某个地址在某个轮次的分红。

## 事件

ShareDividend 合约触发以下事件：

- `withdrawShareEvent(address who, uint avaliableShare, uint shareAmount)`：当所有者提取股份时触发的事件，包括所有者地址、可用股份数量和提取的分红金额。

## 权限控制

ShareDividend 合约使用 Ownable 合约进行权限控制，只有合约的管理员才能执行以下操作：

- 设置分红计算的开始时间。
- 设置与 NFT 合约的地址。
- 将上三轮的利润转移至当前轮。

## 构造函数

ShareDividend 合约继承了 Ownable 合约，构造函数将合约的部署者设置为管理员。

## 支持的标准

ShareDividend 合约基于 ERC721Enumerable 标准。

## 注释

合约中的注释提供了对函数和变量的说明，可以作为参考来理解代码的功能和用法。



<!--
**web3FirstToolbox/web3FirstToolbox** is a ✨ _special_ ✨ repository because its `README.md` (this file) appears on your GitHub profile.

Here are some ideas to get you started:

- 🔭 I’m currently working on ...
- 🌱 I’m currently learning ...
- 👯 I’m looking to collaborate on ...
- 🤔 I’m looking for help with ...
- 💬 Ask me about ...
- 📫 How to reach me: ...
- 😄 Pronouns: ...
- ⚡ Fun fact: ...
-->
