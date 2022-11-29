// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./interfaces/IERC721Receiver.sol";
import "./tokens/ERC721.sol";
import "./tokens/ERC20.sol";
import "./utils/SafeMath.sol";

contract Market is IERC721Receiver {
    ERC20 public erc20;
    ERC721 public erc721;

    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02; //32bits
    struct Order {
        address seller;
        uint256 tokenId;
        uint256 price;
    }

    // 某token订单信息
    mapping(uint256 => Order) public orderOfId; // token id to order

    //订单编号对应的订单
    Order[] public orders;

    // 某token对应的订单编号
    mapping(uint256 => uint256) public idToOrderIndex;

    event Deal(address buyer, address seller, uint256 tokenId, uint256 price);
    event NewOrder(address seller, uint256 tokenId, uint256 price);
    event CancelOrder(address seller, uint256 tokenId);
    event ChangePrice(
        address seller,
        uint256 tokenId,
        uint256 previousPrice,
        uint256 price
    );

    constructor(ERC20 _erc20, ERC721 _erc721) {
        require(
            address(_erc20) != address(0),
            "Market: ERC20 contract address must be non-null"
        );
        require(
            address(_erc721) != address(0),
            "Market: ERC721 contract address must be non-null"
        );
        erc20 = _erc20;
        erc721 = _erc721;
    }
    
    // ④购买nft 
    function buy(uint256 _tokenId, uint256 _price) external {
        // 
        require(isListed(_tokenId) && _price>=orderOfId[_tokenId].price);
        address buyer = msg.sender;
        address seller = orderOfId[_tokenId].seller;
        uint256 price = orderOfId[_tokenId].price;

        ERC20(erc20).transferFrom(msg.sender,orderOfId[_tokenId].seller,orderOfId[_tokenId].price);
        ERC721(erc721).safeTransferFrom(address(this),msg.sender,_tokenId,"data_price");

        removeListing(_tokenId);
        emit Deal(buyer, seller, _tokenId, price);
    }

    // ③下架nft 
    function cancelOrder(uint256 _tokenId) external {
        // 表示上架过 
        require(isListed(_tokenId) && orderOfId[_tokenId].seller == msg.sender);
        address seller = orderOfId[_tokenId].seller;
        ERC721(erc721).safeTransferFrom(address(this),msg.sender,_tokenId,"data_price");

        removeListing(_tokenId);
        emit CancelOrder(seller, _tokenId);
    }

    // ②修改价格
    function changePrice(uint256 _tokenId, uint256 _price) external {
        // 
        require(isListed(_tokenId),"The tokenid is not existing");
        require(msg.sender==orderOfId[_tokenId].seller,"You don't own this coin");
        require(_price != orderOfId[_tokenId].price && _price !=0,"Your revised price is wrong");

        uint256 previousPrice = orderOfId[_tokenId].price;
        address seller = orderOfId[_tokenId].seller;
        orderOfId[_tokenId].price=_price;

        emit ChangePrice(seller, _tokenId, previousPrice, _price);
    }

// 0x0000000000000000000000000000000000000000000000056BC75E2D63100000

// 0x00000000000000000000000000000000000000000000000AD78EBC5AC6200000

// 0x000000000000000000000000000000000000000000000000821AB0D4414980000

        // 保证函数必须执行
    function onERC721Received(
        address _operator,
        address _seller,
        uint256 _tokenId,
        bytes calldata _data
    ) public override returns (bytes4) {
        // 看不太懂
        uint price = toUint256(_data, 0);
        placeOrder(_seller, _tokenId, _price);

        return MAGIC_ON_ERC721_RECEIVED;
    }

    // 检查_tokenId是否正在售卖
    function isListed(uint256 _tokenId) public view returns (bool) {
        return orderOfId[_tokenId].seller != address(0);
    }
    // 多少份订单
    function getOrderLength() public view returns (uint256) {
        return orders.length;
    }


    // ①上架nft 
    function placeOrder(
        address _seller,
        uint256 _tokenId,
        uint256 _price
    ) internal {
        // 表示未上架过,价格不能为0，且_tokenId必须存在==》怎么检查
        require(!isListed((_tokenId)) && _price !=0);

        idToOrderIndex[_tokenId]=getOrderLength()+1;
        orders[idToOrderIndex[_tokenId]] = Order(_seller,_tokenId,_price);
        orderOfId[_tokenId]=orders[idToOrderIndex[_tokenId]];

        ERC721(erc721).safeTransferFrom(msg.sender,address(this),_tokenId,"data_price");


        emit NewOrder(_seller, _tokenId, _price);
    }
    
    // 下架后顺便移除陈列
    function removeListing(uint256 _tokenId) internal {
        
        //订单编号，目前的数组顺序
        uint256  tempRemoveOrder = idToOrderIndex[_tokenId];
        Order memory tempLastOrder = orders[getOrderLength()];

        orders[tempRemoveOrder] = tempLastOrder;
        orders.pop();
        delete orderOfId[_tokenId];

        idToOrderIndex[tempLastOrder.tokenId]= tempRemoveOrder;
        //这一步怎么删除
        idToOrderIndex[_tokenId]= 0;
    }

    // https://stackoverflow.com/questions/63252057/how-to-use-bytestouint-function-in-solidity-the-one-with-assembly
    function toUint256(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint256)
    {
        require(_start + 32 >= _start, "Market: toUint256_overflow");
        require(_bytes.length >= _start + 32, "Market: toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }
}
