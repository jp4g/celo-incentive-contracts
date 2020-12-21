//SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.6.0 < 0.8.0;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/math/SafeMath.sol';

library Users {
    
    using SafeMath for uint;

    /// MODIFIERS ///

    modifier uninitialized(User storage _self) {
        require(_self.role == Role.None, "Users Lib Error: User cannot be reinitialized");
        _;
    }

    /// MUTABLE FUNCTIONS ///

    /**
     * Initialize a new user
     *
     * @param _name - the user's name
     * @param _twitterId - the user's twitter id
     * @param _imageUrl - the user's google profile image url
     */
    function initialize(
        User storage _self,
        string calldata _name, 
        string calldata _twitterId,
        string calldata _imageUrl
    ) internal {
        _self.name = _name;
        _self.twitterId = _twitterId;
        _self.imageUrl = _imageUrl;
        _self.at = msg.sender;
        _self.role = Role.Member;
    }

    /**
     * Promote a user to administrator
     */
    function promote(User storage _self) internal {
        require(
            _self.role == Role.Member,
            "Users Lib Error: Cannot promote user that is not a Member!"
        );
        _self.role = Role.Administrator;
    }

    /**
     * Credit the user's balance
     *
     * @param _balance - the number of tokens to credit the user with
     */
    function credit(User storage _self, uint _balance) internal {
        _self.balance = _self.balance.add(_balance);
    }

    /**
     * Debit the user's balance
     *
     * @param _balance the number of tokens to debit from the user
     */
    function debit(User storage _self, uint _balance) internal {
        require(_self.balance > _balance, "User Lib: Insufficient Balance for Debit!");
        _self.balance = _self.balance.sub(_balance);
    }

    /**
     * Add an item to the user's purchase history
     * 
     * @param _item - the item's identifying nonce
     */
    function addItem(User storage _self, uint _item) internal {
        _self.items.push(_item);
    }

    /**
     * Add a bounty to the user's award history
     * 
     * @param _bounty - the bounty's identifying nonce
     */
    function addBounty(User storage _self, uint _bounty) internal {
        _self.bounties.push(_bounty);
    }

    /// VIEWABLE FUNCTIONS ///
    
    /**
     * Return all data about the user
     */
    function data(User storage _self) internal view returns (
        string memory name,
        string memory twitterId,
        string memory imageUrl,
        uint balance,
        uint role,
        uint[] memory items,
        uint[] memory bounties
    ) {
        name = _self.name;
        twitterId = _self.twitterId;
        imageUrl = _self.imageUrl;
        balance = _self.balance;
        role = uint(_self.role);
        items = _self.items;
        bounties = _self.bounties;
    }
}

enum Role { None, Member, Administrator }

struct User {
    string name;
    string twitterId;
    string imageUrl;
    address at;
    uint balance;
    Role role;
    uint[] items;
    uint[] bounties;
}