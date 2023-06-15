// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./WETH.sol";
import "./SafeMath.sol";

contract DepositContract {
    using SafeMath for uint256;

    address payable public immutable _weth; // 替换为自己部署的 WETH 地址
    uint256 public constant rewardBase = 5; // 每5个币经过一个区块，可以领取1个ETH奖励。注意这里的奖励是ETH而不是WETH；
    uint256 public immutable startBlock; // 在构造函数中定义
    uint256 public immutable endBlock; // 在构造函数中定义
    mapping(address => uint256) public depositAmount; // 用户的存款总量
    mapping(address => uint256) public checkPoint; // 每次存款或提取本金时，更新这个值
    mapping(address => uint256) public calculatedReward; // 已经计算的利息
    mapping(address => uint256) public claimedReward; // 已经提取的利息

    mapping(address => uint256) public lastBlockNumber;//上一次存取款高度

    event Deposit(address indexed sender, uint256 amount);
    event Claim(address indexed sender, address recipient, uint256 amount);
    event Withdraw(address indexed sender, uint256 amount);

    constructor(address payable _wethAddress, uint256 _period) {
        // period 为从当前开始，延续多少个区块
        startBlock = block.number;
        endBlock = block.number + _period + 1;
        _weth = _wethAddress;
    }

    // 修饰符，充值时只允许在设定的区块范围内
    modifier onlyValidTime() {
        require((startBlock >= block.number) && (endBlock <= block.number));
        _;
    }

    // 存款存了多少
    function getDeposit() public view returns (uint256)  {
        return depositAmount[msg.sender];
    }

    //上次存钱时间点（高度）
    function getLastBlockNumber() public view returns (uint256)  {
        if(depositAmount[msg.sender]==0){
            return getBlockNumber();
        }
        else{
            return SafeMath.div(checkPoint[msg.sender],depositAmount[msg.sender]);
        }
    }
    

    // 存钱到合约
    function deposit(uint256 _amount) public onlyValidTime returns (bool) {
        // 此处编写业务逻辑
        require(_amount>0);

        lastBlockNumber[msg.sender] = getLastBlockNumber();

        //每次存本金时更新之前的利息==>上一次到这一次之间
        calculatedReward[msg.sender] = SafeMath.add(calculatedReward[msg.sender] , (block.number-lastBlockNumber[msg.sender])*(depositAmount[msg.sender]/rewardBase));
        //存钱到weth合约，前提是approve了，要不然账户a对此合约没有预存款
        WETH(_weth).transferFrom(msg.sender,address(this),_amount);
        
        depositAmount[msg.sender] = SafeMath.add(depositAmount[msg.sender],_amount);

        checkPoint[msg.sender] = SafeMath.mul(depositAmount[msg.sender],block.number);
        
        emit Deposit(msg.sender, _amount);
        return true;
    }

    //查看一下上次存取款到现在的块利息
    function getBlockReward() public onlyValidTime view returns(uint256) {
        return SafeMath.mul((block.number-getLastBlockNumber()),(depositAmount[msg.sender]/rewardBase));
    }

    // 查询利息
    function getPendingReward(address _account) public view returns (uint256 pendingReward){
        // 此处编写业务逻辑
        return SafeMath.add(SafeMath.sub(calculatedReward[_account],claimedReward[_account]),getBlockReward());
    }


    // 领取利息
    function claimReward(address payable _toAddress) public returns (bool) {
        // 此处编写业务逻辑

        // 记录当前未领取的利息
        uint256  pendingReward = getPendingReward(msg.sender);
        
        WETH(_weth).withdrawTo(_toAddress,pendingReward);
        
        claimedReward[msg.sender] = SafeMath.add(claimedReward[msg.sender],pendingReward);

        // 不用+=，直接更新利息
        //calculatedReward[msg.sender]= claimedReward[msg.sender];
        checkPoint[msg.sender] = SafeMath.mul(depositAmount[msg.sender],block.number);

        emit Claim(msg.sender, _toAddress, pendingReward);
        return true;
    }

    // 提取一定数量的本金
    function withdraw(uint256 _amount) public returns (bool) {
        // 此处编写业务逻辑
        require(_amount>0);
        
        lastBlockNumber[msg.sender]=getLastBlockNumber();

        require(depositAmount[msg.sender]>=_amount);
        claimReward(msg.sender);
        
        WETH(_weth).withdrawTo(msg.sender,_amount);
        depositAmount[msg.sender] = SafeMath.sub(depositAmount[msg.sender],_amount);
        checkPoint[msg.sender] = depositAmount[msg.sender]*block.number;
        
        emit Withdraw(msg.sender, _amount);
        return true;
    }

    // 以下不用改
    // 用于在Remix本地环境中增加区块高度
    uint256 counter;

    function addBlockNumber() public {
        counter++;
    }

    // 获取当前区块高度
    function getBlockNumber() public view returns (uint256) {
        return block.number;
    }
}
