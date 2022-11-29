// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./ERC721.sol";
contract ZYN is ERC721 {
    uint public MAX_ZYNS = 10; // 总量
    address public immutable owner;
    // 构造函数
    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender==owner);
        _;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://voidtech.cn/i/2022/11/21/vz5jtl.jpg";
    }

    // 铸造函数
    function mint(address to, uint tokenId) external onlyOwner {
        require(tokenId >= 0 && tokenId < MAX_ZYNS, "tokenId out of range");
        _mint(to, tokenId);
    }
}