//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IItems.sol";

contract Items is IItems {
    //@param _users - the address of the deployed users contract
    //@param _forwarder - the address of the gsn trusted forwarder
    constructor(address _users, address _forwarder) public {
        userContract = IUsers(_users);
        userContract.setItem(address(this));
        trustedForwarder = _forwarder;
    }

    /// MUTABLE FUNCTIONS ///

    function addItem(
        string memory _title,
        string memory _description,
        string memory _imageUrl,
        uint256 _cost,
        bool _infinite,
        uint256 _quantity
    ) public override onlyAdmin() returns (uint256 _nonce) {
        itemNonce = itemNonce.add(1);
        _nonce = itemNonce;
        Item storage item = items[_nonce];
        item.title = _title;
        item.description = _description;
        item.imageUrl = _imageUrl;
        item.cost = _cost;
        item.infinite = _infinite;
        item.quantity = _quantity;
        item.active = true;
        emit ItemAdded(_nonce);
    }

    function buyItem(uint256 _nonce)
        public
        override
        beforeItemBuy(_nonce)
        returns (uint256 _balance)
    {
        Item storage item = items[_nonce];
        if (!item.infinite) {
            item.quantity = item.quantity.sub(1);
            if (item.quantity == 0) {
                item.active = false;
                emit ItemDelisted(_nonce);
            }
        }
        item.owners.push(_msgSender());
        item.purchased[_msgSender()] = true;
        userContract.addItem(_msgSender(), _nonce, item.cost);
        emit ItemPurchased(_nonce, _msgSender(), item.cost);
        return userContract.balanceOf(_msgSender());
    }

    function delistItem(uint256 _nonce) public override onlyAdmin() {
        Item storage item = items[_nonce];
        item.active = false;
        emit ItemDelisted(_nonce);
    }

    /// VIEWABLE FUNCTIONS ///

    function getItems()
        public
        view
        override
        returns (
            uint256 _itemNonce,
            string[] memory _titles,
            string[] memory _descriptions,
            string[] memory _imageUrls,
            uint256[] memory _costs,
            bool[] memory _infinites,
            uint256[] memory _quantities,
            bool[] memory _actives
        )
    {
        _itemNonce = itemNonce;
        _titles = new string[](_itemNonce);
        _descriptions = new string[](_itemNonce);
        _imageUrls = new string[](_itemNonce);
        _costs = new uint256[](_itemNonce);
        _infinites = new bool[](_itemNonce);
        _quantities = new uint256[](_itemNonce);
        _actives = new bool[](_itemNonce);
        for (uint256 i = 0; i < _itemNonce; i++) {
            _titles[i] = items[i.add(1)].title;
            _descriptions[i] = items[i.add(1)].description;
            _imageUrls[i] = items[i.add(1)].imageUrl;
            _costs[i] = items[i.add(1)].cost;
            _infinites[i] = items[i.add(1)].infinite;
            _quantities[i] = items[i.add(1)].quantity;
            _actives[i] = items[i.add(1)].active;
        }
    }
}
