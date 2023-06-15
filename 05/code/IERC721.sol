// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC165.sol";

/**
 * @dev ERC721标准接口.
 */
interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
// 查看owner拥有多少nft
    function balanceOf(address owner) external view returns (uint256 balance);
// 查看tokenid属于谁
    function ownerOf(uint256 tokenId) external view returns (address owner);
// from给to转自己的tokenid，还可以附带一些信息data
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
// from给to转自己的tokenid
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
// from给to转自己的tokenid
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

// 给to使用tokenid的权利，仅限某个tokenid
    function approve(address to, uint256 tokenId) external;
// 给to使用tokenid的权利，是所有的
    function setApprovalForAll(address operator, bool _approved) external;
// 查看拥有tokenid使用权的人是谁
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);
// 查看owner是否给operator全部nft使用权
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}
