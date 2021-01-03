//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "./ICore.sol";

/**
 * OrgToken contract
 */
contract Core is ICore {
    /// USER FUNCTIONS ///

    constructor() public {
        userNonce = userNonce.add(1);
        userID[msg.sender] = userNonce;
        User storage user = users[userNonce];
        user.name = "Deployment Administrator";
        user.twitterId = "mubcblockchain";
        user.imageUrl = "AOh14GgHdiwS3EV4d5EXfbXC4mNcEONbthxkBNQllmjz";
        user.role = Role.Administrator;
    }

    function enroll(
        string calldata _name,
        string calldata _twitterId,
        string calldata _imageUrl
    ) external override returns (uint256 _nonce) {
        require(userID[msg.sender] == 0, "Core: User Already Enrolled!");
        userNonce = userNonce.add(1);
        userID[msg.sender] = userNonce;
        User storage user = users[userNonce];
        user.name = _name;
        user.twitterId = _twitterId;
        user.imageUrl = _imageUrl;
        user.at = msg.sender;
        user.role = Role.Member;
        emit UserEnrolled(msg.sender);
        _nonce = userNonce;
    }

    function promote(address _user) external override onlyAdmin() {
        User storage user = users[userID[_user]];
        require(
            user.role == Role.Member,
            "Core: Only Members Can Be Promoted!"
        );
        user.role = Role.Administrator;
        emit UserPromoted(_user);
    }

    function setTwitterId(string calldata _twitterId)
        external
        override
        onlyUser()
    {
        require(
            keccak256(bytes(_twitterId)) != keccak256(bytes("")),
            "Core: Must set twitter ID to non-null value!"
        );
        users[userID[msg.sender]].twitterId = _twitterId;
        emit TwitterIDUpdated(msg.sender);
    }

    function getUsers()
        external
        override
        view
        returns (
            uint256 _nonce,
            string[] memory _names,
            string[] memory _imageUrls,
            uint256[] memory _balances,
            uint256[] memory _roles
        )
    {
        _nonce = userNonce;
        _names = new string[](_nonce);
        _imageUrls = new string[](_nonce);
        _balances = new uint256[](_nonce);
        _roles = new uint256[](_nonce);
        for (uint256 i = 0; i < _nonce; i++) {
            _names[i] = users[i.add(1)].name;
            _imageUrls[i] = users[i.add(1)].imageUrl;
            _balances[i] = users[i.add(1)].balance;
            _roles[i] = uint256(users[i.add(1)].role);
        }
    }

    /// ANNOUNCEMENT FUNCTIONS ///
    function pinAnnouncement(uint256 _nonce) public override onlyAdmin() {
        require(_nonce != 0, "Core: cannot set no pinned announcement!");
        require(
            pinnedAnnouncement != _nonce,
            "Core: Announcement already pinned!"
        );
        pinnedAnnouncement = _nonce;
        emit AnnouncementPinned(_nonce);
    }

    function addAnnouncement(
        string calldata _title,
        string calldata _body,
        bool _pin
    ) external override onlyAdmin() returns (uint256 _nonce) {
        announcementNonce = announcementNonce.add(1);
        Announcement storage announcement = announcements[announcementNonce];
        announcement.title = _title;
        announcement.body = _body;
        announcement.timecode = now;
        emit AnnouncementAdded(announcementNonce);
        if (_pin) pinAnnouncement(announcementNonce);
        return announcementNonce;
    }

    function getAnnouncements()
        external
        override
        view
        returns (
            uint256 _nonce,
            string[] memory _titles,
            string[] memory _bodies,
            uint256[] memory _timecodes,
            uint256 _pinned
        )
    {
        _nonce = announcementNonce;
        _pinned = pinnedAnnouncement;
        _titles = new string[](_nonce);
        _bodies = new string[](_nonce);
        _timecodes = new uint256[](_nonce);
        for (uint256 i = 0; i < _nonce; i++) {
            _titles[i] = announcements[i.add(1)].title;
            _bodies[i] = announcements[i.add(1)].body;
            _timecodes[i] = announcements[i.add(1)].timecode;
        }
    }

    /// ITEM FUNCTIONS ///

    function addItem(
        string calldata _title,
        string calldata _description,
        string calldata _imageUrl,
        uint256 _cost,
        bool _infinite,
        uint256 _quantity
    ) external override onlyAdmin() returns (uint256 _nonce) {
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
        external
        override
        beforeItemBuy(_nonce)
        returns (uint256 _balance)
    {
        // Item storage item = items[_nonce];
        // if (!item.infinite) {
        //     item.quantity = item.quantity.sub(1);
        //     if (item.quantity == 0) this.delistItem(_nonce);
        // }
        // item.owners.push(msg.sender);
        // item.purchased[msg.sender] = true;
        // User storage user = users[userID[msg.sender]];
        // user.balance = user.balance.sub(item.cost);
        // user.items.push(_nonce);
        // emit ItemPurchased(_nonce, msg.sender, item.cost);
        // return user.balance;
    }

    function delistItem(uint256 _nonce) external override onlyAdmin() {
        // Item storage item = items[_nonce];
        // item.active = false;
        // emit ItemDelisted(_nonce);
    }

    function getItems()
        external
        override
        view
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

    /// BOUNTY FUNCTIONS ///

    function addBounty(
        string calldata _title,
        string calldata _description,
        string calldata _imageUrl,
        uint256 _award,
        bool _infinite,
        uint256 _quantity,
        string calldata _tweet
    ) external override onlyAdmin() returns (uint256 _nonce) {
        bountyNonce = bountyNonce.add(1);
        _nonce = bountyNonce;
        Bounty storage bounty = bounties[_nonce];
        //trigger initialization would need to be more robust with > 1 chainlink adapter
        bool manual = keccak256(bytes(_tweet)) == keccak256(bytes(""));
        Trigger trigger = manual ? Trigger.Manual : Trigger.Twitter;
        bounty.name = _title;
        bounty.description = _description;
        bounty.imageUrl = _imageUrl;
        bounty.award = _award;
        bounty.infinite = _infinite;
        bounty.quantity = _quantity;
        bounty.trigger = trigger;
        bounty.tweet = _tweet;
        bounty.active = true;
        emit BountyAdded(_nonce);
    }

    function delistBounty(uint256 _nonce) external override {
        Bounty storage bounty = bounties[_nonce];
        bounty.active = false;
        emit BountyDelisted(_nonce);
    }

    function applyForBounty(uint256 _nonce)
        external
        override
        onlyUser()
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
        external
        override
        onlyAdmin()
    {
        Pending memory pending = pendings[_trigger][_nonce];
        Bounty storage bounty = bounties[pending.bounty];
        //LOGIC FOR CHAINLINK HERE
        //@dev make sure manual only approves manual and link only approves link
        if (!bounty.infinite) {
            bounty.quantity = bounty.quantity.sub(1);
            if (bounty.quantity == 0) this.delistBounty(pending.bounty);
        }
        bounty.status[pending.user] = BountyState.Awarded;
        bounty.holders.push(pending.user);
        User storage user = users[userID[pending.user]];
        user.balance = user.balance.add(bounty.award);
        user.bounties.push(pending.bounty);
        emit BountyAwarded(pending.bounty, pending.user, bounty.award);
        removePendingRequest(_trigger, _nonce);
    }

    function rejectBountyRequest(uint256 _trigger, uint256 _nonce)
        external
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

    function pendingBountyRequests(uint256 _trigger)
        external
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
        external
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
