//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IUsers.sol";

contract Users is IUsers {
    // @param _name - the name of the admin
    // @param _twitterId - the twitter id of the admin
    // @param _imageUrl - the google profile photo of the admin
    // @param _forwarder - the address of the gsn trusted forwarder
    constructor(
        string memory _name,
        string memory _twitterId,
        string memory _imageUrl,
        address _forwarder
    ) public {
        enroll(_name, _twitterId, _imageUrl);
        users[userNonce].role = Role.Administrator;
        trustedForwarder = _forwarder;
    }

    /// MUTABLE FUNCTIONS ///

    function enrollAdmin(
        address _at,
        string memory _name,
        string memory _twitterId,
        string memory _imageUrl
    ) public override onlyAdmin() returns (uint256 _nonce) {
        userNonce = userNonce.add(1);
        userID[_at] = userNonce;
        User storage user = users[userNonce];
        user.name = _name;
        user.twitterId = _twitterId;
        user.imageUrl = _imageUrl;
        user.at = _at;
        user.role = Role.Administrator;
        emit UserEnrolled(_at);
        _nonce = userNonce;
    }

    function enroll(
        string memory _name,
        string memory _twitterId,
        string memory _imageUrl
    ) public override returns (uint256 _nonce) {
        require(userID[_msgSender()] == 0, "User is enrolled");
        userNonce = userNonce.add(1);
        userID[_msgSender()] = userNonce;
        User storage user = users[userNonce];
        user.name = _name;
        user.twitterId = _twitterId;
        user.imageUrl = _imageUrl;
        user.at = _msgSender();
        user.role = Role.Member;
        emit UserEnrolled(_msgSender());
        _nonce = userNonce;
    }

    function promote(address _user) public override onlyAdmin() {
        User storage user = users[userID[_user]];
        require(user.role == Role.Member, "Can only promote a Member");
        user.role = Role.Administrator;
        emit UserPromoted(_user);
    }

    function setTwitterId(string memory _twitterId) public override {
        users[userID[_msgSender()]].twitterId = _twitterId;
        emit TwitterIDUpdated(_msgSender());
    }

    function setBounty(address _at) public override {
        require(bountyContract == address(0));
        bountyContract = _at;
    }

    function addItem(
        address _user,
        uint256 _item,
        uint256 _value
    ) public override {
        require(
            msg.sender == itemContract,
            "Call is restricted to item contract"
        );
        User storage user = users[userID[_user]];
        user.items.push(_item);
        user.balance = user.balance.sub(_value);
    }

    function setItem(address _at) public override {
        require(itemContract == address(0));
        itemContract = _at;
    }

    function addBounty(
        address _user,
        uint256 _bounty,
        uint256 _value
    ) public override {
        require(
            msg.sender == bountyContract,
            "Call is restricted to bounty contract"
        );
        User storage user = users[userID[_user]];
        user.bounties.push(_bounty);
        user.balance = user.balance.add(_value);
    }

    /// VIEWABLE FUNCTIONS ///

    function role(address _user) public view override returns (uint256 _role) {
        _role = uint256(users[userID[_user]].role);
    }

    function balanceOf(address _user)
        public
        view
        override
        returns (uint256 _balance)
    {
        _balance = users[userID[_user]].balance;
    }

    function name(address _user)
        public
        view
        override
        returns (string memory _name)
    {
        _name = users[userID[_user]].name;
    }

    function getUser(address _user)
        public
        view
        override
        returns (
            string memory _name,
            string memory _imageUrl,
            string memory _twitterId,
            uint256 _balance,
            uint256 _role,
            uint256[] memory _items,
            uint256[] memory _bounties,
            address _at
        )
    {
        User memory user = users[userID[_user]];
        _name = user.name;
        _imageUrl = user.imageUrl;
        _twitterId = user.twitterId;
        _balance = user.balance;
        _role = uint256(user.role);
        _items = user.items;
        _bounties = user.bounties;
        _at = user.at;
    }

    function getUsers()
        public
        view
        override
        returns (
            uint256 _nonce,
            string[] memory _names,
            string[] memory _imageUrls,
            uint256[] memory _balances,
            uint256[] memory _roles,
            address[] memory _ats
        )
    {
        _nonce = userNonce;
        _names = new string[](_nonce);
        _imageUrls = new string[](_nonce);
        _balances = new uint256[](_nonce);
        _roles = new uint256[](_nonce);
        _ats = new address[](_nonce);
        for (uint256 i = 0; i < _nonce; i++) {
            _names[i] = users[i.add(1)].name;
            _imageUrls[i] = users[i.add(1)].imageUrl;
            _balances[i] = users[i.add(1)].balance;
            _roles[i] = uint256(users[i.add(1)].role);
            _ats[i] = users[i.add(1)].at;
        }
    }

    function getTwitterId(address _from)
        public
        view
        override
        returns (string memory)
    {
        return users[userID[_from]].twitterId;
    }
}
