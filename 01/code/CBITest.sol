//SPDX-License-Identify:MIT
pragma solidity ^0.8.0;
contract zhouyanan{

//获取一个地址的CBI余额
function getBalance(address _user) view private returns(uint){
    return _user.balance;
}

//获取一个区块的哈希值
function getHash(uint _blockNumber) view private returns(bytes32){
    return blockhash(_blockNumber);
}

// 获取上一个区块的哈希值
function getLastBlockHash() view private returns(bytes32){
    return blockhash(block.number-1);
}

//获取当前的时间戳
function getCurrentTimestamp() view private returns(uint){
    return block.timestamp;
}

// 获取当前区块的高度
function getCurrentBlockHeight() view private returns(uint){
    return block.number;
}

// 获取当前区块的难度(difficulty)
function getCurrentBlockDifficulty() view private returns(uint){
    return block.difficulty;
}

// 获取当前区块的gas limit
function getCurrentBlockGasLimit() view private returns(uint){
    return block.gaslimit;
}

// 获取当前区块的coinbase账户
function getCurrentBlockAccount() view private returns(address){
    return block.coinbase;
}

}