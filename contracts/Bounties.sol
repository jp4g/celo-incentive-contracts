//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IBounties.sol";
import "./interfaces/ITwitterConsumer.sol";

contract Bounties is IBounties {
    //@param _users - the address of the deployed users contract
    constructor(address _users) public {
        userContract = IUsers(_users);
        userContract.setBounty(address(this));
    }

    /// MUTABLE FUNCTIONS ///

    function setConsumer(address _at) public override {
        require(consumerContract == address(0));
        consumerContract = _at;
        consumerInstance = ITwitterConsumer(_at);
    }

    function addBounty(
        string memory _title,
        string memory _description,
        string memory _imageUrl,
        uint256 _award,
        bool _infinite,
        uint256 _quantity,
        bool _manual,
        string memory _tweetId
    ) public override adminOrTwitter(uint(Trigger.Manual)) returns (uint256 _nonce) {
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
        requestNonce = requestNonce.add(1);
        pendingIndices[trigger] = pendingIndices[trigger].add(1);
        pendingRequests[trigger][pendingIndices[trigger]] = requestNonce;
        Request storage request = requests[requestNonce];
        request.user = msg.sender;
        request.bounty = _nonce;
        request.pendingIndex = pendingIndices[trigger];
        bounty.status[msg.sender] = BountyState.Pending;
        if (bounty.trigger == Trigger.Twitter) {
            string memory userId = userContract.getTwitterId(request.user);
            string memory tweetId = bounty.tweet;
            bytes32 requestId = consumerInstance.checkRetweets(userId, tweetId);
            chainlinkRequests[requestId] = requestNonce;
            nonceToRequestId[requestNonce] = requestId;
        }
        emit BountyApplication(_nonce, msg.sender, requestNonce);
    }

    function approveBountyRequest(uint256 _trigger, uint256 _index)
        public
        override
    {
        uint requestNonce = pendingRequests[_trigger][_index];
        Request memory request = requests[requestNonce];
        Bounty storage bounty = bounties[request.bounty];
        if (!bounty.infinite) {
            bounty.quantity = bounty.quantity.sub(1);
            if (bounty.quantity == 0) delistBounty(request.bounty);
        }
        bounty.status[request.user] = BountyState.Awarded;
        bounty.holders.push(request.user);
        userContract.addBounty(request.user, request.bounty, bounty.award);
        userHasBounty[request.bounty][request.user] = true;
        emit BountyAwarded(request.bounty, request.user, bounty.award);
        removePendingRequest(_trigger, _index);
    }

    function rejectBountyRequest(uint256 _trigger, uint256 _index)
        public
        override
        adminOrTwitter(uint(Trigger.Twitter))
    {
        uint requestNonce = pendingRequests[_trigger][_index];
        Request memory request = requests[requestNonce];
        Bounty storage bounty = bounties[request.bounty];
        bounty.status[request.user] = BountyState.None;
        tempban[request.bounty][request.user] = now;
        userHasBounty[request.bounty][request.user] = false;
        emit BountyRejected(request.bounty, request.user);
        removePendingRequest(_trigger, _index);
    }

    function delistBounty(uint256 _nonce) public override adminOrTwitter(uint(Trigger.Manual)) {
        Bounty storage bounty = bounties[_nonce];
        bounty.active = false;
        emit BountyDelisted(_nonce);
    }

    /**
     * Internal helper function to handle logic of removing pending requests from storage
     *
     * @param _trigger - the type of request being removed
     * @dev can add more uint/ enum codes for triggers. 1 = manual, 2 = retweet verification
     * @param _index - the index of the pending request to remove
     */
    function removePendingRequest(uint256 _trigger, uint256 _index) internal {
        uint pendingIndex = pendingIndices[_trigger];
        uint lastNonce = pendingRequests[_trigger][pendingIndex];
        Request storage last = requests[lastNonce];
        if (_index != pendingIndex) {
            uint swapNonce = pendingRequests[_trigger][_index];
            Request storage swap = requests[swapNonce];
            swap.user = last.user;
            swap.bounty = last.bounty;
        }
        pendingRequests[_trigger][pendingIndex] = 0;
        pendingIndices[_trigger] = pendingIndices[_trigger].sub(1);
    }

    function fulfillChainlinkRequest(bytes32 _requestId, bool _status)
        public
        override
    {
        uint256 trigger = uint256(Trigger.Twitter);
        Request storage request = requests[chainlinkRequests[_requestId]];
        if (_status) 
            approveBountyRequest(trigger, request.pendingIndex);
        else 
            rejectBountyRequest(trigger, request.pendingIndex);
        request.fulfilled = true;
    }

    /// VIEWABLE FUNCTIONS ///

    function pendingBountyRequests(uint256 _trigger)
        public
        view
        override
        returns (
            uint256 _nonce,
            address[] memory _users,
            string[] memory _userNames,
            uint256[] memory _bounties,
            string[] memory _bountyNames
        )
    {
        _nonce = pendingIndices[_trigger];
        _users = new address[](_nonce);
        _userNames = new string[](_nonce);
        _bounties = new uint256[](_nonce);
        _bountyNames = new string[](_nonce);
        for (uint256 i = 0; i < _nonce; i++) {
            uint requestNonce = pendingRequests[_trigger][i.add(1)];
            _users[i] = requests[requestNonce].user;
            _userNames[i] = userContract.name(_users[i]);
            _bounties[i] = requests[requestNonce].bounty;
            _bountyNames[i] = bounties[_bounties[i]].name;
        }
    }

    function getBounties()
        public
        view
        override
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

    function hasBounty(uint256 _bountyNonce, address _user)
        public
        view
        override
        returns (bool)
    {
        return userHasBounty[_bountyNonce][_user];
    }

    function checkFulfillment(uint256 _nonce)
        public
        view
        override
        returns (bool)
    {
        return requests[_nonce].fulfilled;
    }
}
