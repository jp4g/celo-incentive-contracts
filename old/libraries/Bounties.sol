//SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.6.0 < 0.8.0;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/math/SafeMath.sol';

library Bounties {

    using SafeMath for uint;

    modifier active(Bounty storage _self) {
        require(_self.active, "Bounty Error: Bounty not active!");
        _;
    }

    modifier inStock(Bounty storage _self) {
        require(_self.infinite || _self.quantity > 0, "Bounty Error: Bounty not in stock!");
        _;
    }

    function initialize(
        Bounty storage _self,
        string memory _name,
        string memory _description,
        string memory _imageUrl,
        uint _award,
        bool _infinite,
        uint _quantity,
        Trigger _trigger,
        string memory _tweet
    ) internal {
        require(_self.award > 0, "Bounty already initialized at this storage space!");
        _self.name = _name;
        _self.description = _description;
        _self.imageUrl = _imageUrl;
        _self.award = _award;
        _self.infinite = _infinite;
        _self.quantity = _quantity;
        _self.trigger = _trigger;
        _self.tweet = _tweet;
    }

    function application(Bounty storage _self) internal inStock(_self) active(_self) returns (bool) {
        _self.pendingNonce = _self.pendingNonce.add(1);
        _self.status[msg.sender] = BountyState.Pending;
        if (_self.trigger == Trigger.Manual)
            return false;
        else {
            return checkTweet(_self, msg.sender);
        }
    }

    //CHAINLINK LOGIC GOES HERE
    function checkTweet(Bounty storage _self, address _user) internal returns (bool) {
        _self.pendingNonce = _self.pendingNonce.sub(1);
        _self.status[msg.sender] = BountyState.None;
        _user; //useless line other than silencing compilation warnings
        return false;
    }


    function approve(Bounty storage _self, address _user) internal {
        _self.pendingNonce = _self.pendingNonce.sub(1);
        if (!_self.infinite) {
            _self.quantity = _self.quantity.sub(1);
            if (_self.quantity == 0)
                delist(_self);
        }
        _self.status[_user] = BountyState.Awarded;
        _self.holders.push(_user);
    }

    function reject(Bounty storage _self, address _user) internal {
        _self.pendingNonce = _self.pendingNonce.sub(1);
        _self.status[_user] = BountyState.None;
    }

    function delist(Bounty storage _self) internal active(_self) {
        _self.active = false;
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
    Trigger trigger;
    string tweet;
    uint pendingNonce;
    mapping(address => BountyState) status;
    address[] holders;
}

struct Pending {
    address user;
    uint256 bounty;
}

enum BountyState { None, Pending, Awarded }
enum Trigger { None, Manual, Twitter }