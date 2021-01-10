//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IUsers.sol";

contract Users is IUsers {

    // @param _name - the name of the admin
    // @param _twitterId - the twitter id of the admin
    // @param _imageUrl - the google profile photo of the admin
    constructor(
        string memory _name,
        string memory _twitterId,
        string memory _imageUrl
    ) public {
        enroll(
            _name,
            _twitterId,
            _imageUrl
        );
        users[userNonce].role = Role.Administrator;
    }

    /// MUTABLE FUNCTIONS ///

    function enroll(
        string memory _name,
        string memory _twitterId,
        string memory _imageUrl
    ) public override returns (uint256 _nonce) {
        require(userID[msg.sender] == 0, "User is enrolled");
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

    function promote(address _user) public override onlyAdmin() {
        User storage user = users[userID[_user]];
        require(user.role == Role.Member, "Can only promote a Member");
        user.role = Role.Administrator;
        emit UserPromoted(_user);
    }

    function setTwitterId(string memory _twitterId) public override {
        users[userID[msg.sender]].twitterId = _twitterId;
        emit TwitterIDUpdated(msg.sender);
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

    function role(address _user) public override view returns (uint256 _role) {
        _role = uint256(users[userID[_user]].role);
    }

    function balanceOf(address _user)
        public
        override
        view
        returns (uint256 _balance)
    {
        _balance = users[userID[_user]].balance;
    }

    function getUser(address _user)
        public
        override
        view
        returns (
            string memory _name,
            string memory _imageUrl,
            string memory _twitterId,
            uint256 _balance,
            uint256 _role,
            uint256[] memory _items,
            uint256[] memory _bounties
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
    }

    function getUsers()
        public
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

    function getTwitterId(address _from)
        public
        override
        view
        returns (string memory) 
    {
        return users[userID[_from]].twitterId;
    }
}
