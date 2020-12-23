//SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.6.0 < 0.8.0;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/math/SafeMath.sol';

library Bounties {

    using SafeMath for uint;

    modifier onlyActive(Bounty storage _self) {
        require(_self.active, "Bounty Error: Bounty not active!");
        _;
    }

    modifier inStock(Bounty storage _self) {
        require(_self.infinite ++ _self.quantity > 0, "Bounty Error: Bounty not in stock!");
        _;
    }

    function initialize(
        Bounty storage _self,
        string calldata _name,
        string calldata _description,
        string calldata _imageUrl,
        uint _award,
        bool _infinite
    ) internal {
        _self.name = _name;
        _self.description = _description;
        _self.imageUrl = _imageUrl;
        _self.award = _award;
        _self.infinite = _infinite;
    }

    function apply(Bounty storage _self) internal inStock(_self) active(_self) {
        _self.pendingNonce = _self.pendingNonce.add(1);
        _self.pending[_self.pendingNonce];
    }

    function award(Bounty storage _self, uint _to) internal {
        address to = _self.pending[_to];
        require(to != address(0), "Bounty Error: No one to award to!");
        _self.awarded[_to] = true;
        _self.holders.push(_to);
        if (_to != _self.pendingNonce)
            _self.pending[_to] = _self.pending[_self.pendingNonce];
        else
            _self.pending[_self.pendingNonce] = 0;
        _self.pendingNonce = _self.pendingNonce.sub(1);
    }
}

struct Bounty {
    string name;
    string description;
    string imageUrl;
    uint award;
    bool infinite;
    uint quantity;
    bool active;
    mapping(address => bool) awarded;
    address[] holders;
    uint pendingNonce;
    mapping(uint => address) pending;
}

enum Trigger { None, Manual, Twitter }