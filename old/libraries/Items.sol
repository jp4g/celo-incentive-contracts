//SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.6.0 < 0.8.0;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/math/SafeMath.sol';

library Items {
    
    using SafeMath for uint;

    modifier inStock(Item storage _self) {
        require(_self.infinite || _self.quantity > 0, "Item Error: Item not in Stock!");
        _;
    }

    modifier active(Item storage _self) {
        require(_self.active, "Item is no longer active!");
        _;
    }

    function initialize(
        Item storage _self,
        string memory _title,
        string memory _description,
        string memory _imageUrl,
        uint _cost,
        bool _infinite,
        uint _quantity
    ) internal {
        require(_self.cost == 0, "Item Error: Cannot initialize twice!");
        _self.title = _title;
        _self.description = _description;
        _self.imageUrl = _imageUrl;
        _self.cost = _cost;
        _self.infinite = _infinite;
        _self.quantity = _quantity;
        _self.active = true;
    }

    function buy(Item storage _self) internal active(_self) inStock(_self) {
        require(!_self.purchased[msg.sender], "Items Error: Cannot Purchase Item Twice!");
        _self.purchased[msg.sender] = true;
        _self.owners.push(msg.sender);
        _self.quantity = _self.quantity.sub(1);
    }

    function deactivate(Item storage _self) internal active(_self) {
        _self.active = false;
    }

    function data(Item storage _self) internal view returns(
        string memory _title,
        string memory _description,
        string memory _imageUrl,
        uint _cost,
        bool _infinite,
        uint _quantity,
        bool _active,
        address[] memory _owners
    ) {
        _title = _self.title;
        _description = _self.description;
        _imageUrl = _self.imageUrl;
        _cost = _self.cost;
        _infinite = _self.infinite;
        _quantity = _self.quantity;
        _active = _self.active;
        _owners = _self.owners;
    }
}

struct Item {
    string title;
    string description;
    string imageUrl;
    uint cost;
    bool infinite;
    uint quantity;
    bool active;
    mapping(address => bool) purchased;
    address[] owners;
}