//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IBounties.sol";

contract Bounties is IBounties {
    //@param _users - the address of the deployed users contract
    constructor(address _users) public {
        userContract = IUsers(_users);
        userContract.setBounty(address(this));
    }

    /// MUTABLE FUNCTIONS ///

    function addBounty(
        string memory _title,
        string memory _description,
        string memory _imageUrl,
        uint256 _award,
        bool _infinite,
        uint256 _quantity,
        bool _manual,
        string memory _tweetId
    ) public override onlyAdmin() returns (uint256 _nonce) {
        bountyNonce = bountyNonce.add(1);
        _nonce = bountyNonce;
        Bounty storage bounty = bounties[_nonce];
        //trigger initialization would need to be more robust with > 1 chainlink adapter
        Trigger trigger = _manual ? Trigger.Manual : Trigger.Twitter;
        bounty.name = _title;
        bounty.description = _description;
        bounty.imageUrl = _imageUrl;
        bounty.award = _award;
        bounty.infinite = _infinite;
        bounty.quantity = _quantity;
        bounty.trigger = trigger;
        bounty.tweet = _tweetId;
        bounty.active = true;
        emit BountyAdded(_nonce);
    }

    function applyForBounty(uint256 _nonce)
        public
        override
        beforeBountyApp(_nonce)
    {
        Bounty storage bounty = bounties[_nonce];
        uint256 trigger = uint256(bounty.trigger);
        pendingNonces[trigger] = pendingNonces[trigger].add(1);

        Pending storage pending = pendings[trigger][pendingNonces[trigger]];
        pending.user = msg.sender;
        pending.bounty = _nonce;
        bounty.status[msg.sender] = BountyState.Pending;
        emit BountyApplication(_nonce, msg.sender);
    }

    function approveBountyRequest(uint256 _trigger, uint256 _nonce)
        public
        override

    {
        Pending memory pending = pendings[_trigger][_nonce];
        Bounty storage bounty = bounties[pending.bounty];
        //LOGIC FOR CHAINLINK HERE
        //@dev make sure manual only approves manual and link only approves link
        if (!bounty.infinite) {
            bounty.quantity = bounty.quantity.sub(1);
            if (bounty.quantity == 0) delistBounty(pending.bounty);
        }
        bounty.status[pending.user] = BountyState.Awarded;
        bounty.holders.push(pending.user);
        userContract.addBounty(pending.user, pending.bounty, bounty.award);
        emit BountyAwarded(pending.bounty, pending.user, bounty.award);
        removePendingRequest(_trigger, _nonce);
    }

    function rejectBountyRequest(uint256 _trigger, uint256 _nonce)
        public
        override
        onlyAdmin()
    {
        Pending memory pending = pendings[_trigger][_nonce];
        Bounty storage bounty = bounties[pending.bounty];
        bounty.status[pending.user] = BountyState.None;
        tempban[pending.bounty][pending.user] = now;
        emit BountyRejected(pending.bounty, pending.user);
        removePendingRequest(_trigger, _nonce);
    }

    function delistBounty(uint256 _nonce) public override onlyAdmin() {
        Bounty storage bounty = bounties[_nonce];
        bounty.active = false;
        emit BountyDelisted(_nonce);
    }

    /**
     * Internal helper function to handle logic of removing pending requests from storage
     *
     * @param _trigger - the type of request being removed
     * @dev can add more uint/ enum codes for triggers. 1 = manual, 2 = retweet verification
     * @param _nonce - the index of the pending request to remove
     */
    function removePendingRequest(uint256 _trigger, uint256 _nonce) internal {
        Pending storage last = pendings[_trigger][pendingNonces[_trigger]];
        if (_nonce != pendingNonces[_trigger]) {
            Pending storage swap = pendings[_trigger][_nonce];
            swap.user = last.user;
            swap.bounty = last.bounty;
        }
        last.user = address(0);
        last.bounty = 0;
        pendingNonces[_trigger] = pendingNonces[_trigger].sub(1);
    }

    /// VIEWABLE FUNCTIONS ///

    function pendingBountyRequests(uint256 _trigger)
        public
        override
        view
        returns (
            uint256 _nonce,
            address[] memory _users,
            uint256[] memory _bounties
        )
    {
        _nonce = pendingNonces[_trigger];
        _users = new address[](_nonce);
        _bounties = new uint256[](_nonce);
        for (uint256 i = 0; i < _nonce; i++) {
            _users[i] = pendings[_trigger][i.add(1)].user;
            _bounties[i] = pendings[_trigger][i.add(1)].bounty;
        }
    }

    function getBounties()
        public
        override
        view
        returns (
            uint256 _bountyNonce,
            string[] memory _titles,
            string[] memory _descriptions,
            string[] memory _imageUrls,
            uint256[] memory _awards,
            bool[] memory _infinites,
            uint256[] memory _quantities,
            bool[] memory _actives,
            bool[] memory _manuals
        )
    {
        _bountyNonce = bountyNonce;
        _titles = new string[](_bountyNonce);
        _descriptions = new string[](_bountyNonce);
        _imageUrls = new string[](_bountyNonce);
        _awards = new uint256[](_bountyNonce);
        _infinites = new bool[](_bountyNonce);
        _quantities = new uint256[](_bountyNonce);
        _actives = new bool[](_bountyNonce);
        _manuals = new bool[](_bountyNonce);
        for (uint256 i = 0; i < _bountyNonce; i++) {
            _titles[i] = bounties[i.add(1)].name;
            _descriptions[i] = bounties[i.add(1)].description;
            _imageUrls[i] = bounties[i.add(1)].imageUrl;
            _awards[i] = bounties[i.add(1)].award;
            _infinites[i] = bounties[i.add(1)].infinite;
            _quantities[i] = bounties[i.add(1)].quantity;
            _actives[i] = bounties[i.add(1)].active;
            _manuals[i] = bounties[i.add(1)].trigger == Trigger.Manual;
        }
    }
}
