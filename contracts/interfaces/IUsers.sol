//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@opengsn/gsn/contracts/BaseRelayRecipient.sol";

abstract contract IUsers is BaseRelayRecipient {
    using SafeMath for uint256;

    /// EVENTS ///

    event UserEnrolled(address _user);
    event UserPromoted(address _user);
    event TwitterIDUpdated(address _user);

    /// MODIFIERS ///

    modifier onlyAdmin() {
        require(
            users[userID[_msgSender()]].role == Role.Administrator,
            "Caller is not an administrator"
        );
        _;
    }

    address public itemContract;
    address public bountyContract;
    uint256 public userNonce;
    mapping(address => uint256) public userID;
    mapping(uint256 => User) public users;
    string public override versionRecipient = "2.0.0";

    /// MUTABLE FUNCTIONS ///

    /**
     * Automatically enroll an account as an administrator
     * @dev modifier onlyAdmin
     * @dev function exists only to make team development easier
     *
     * @param _at - the address being enrolled
     * @param _name - the name of the user being enrolled as an administrator
     * @param _twitterId - the twitterId of the user being enrolled as an administrator
     * @param _imageUrl - the google profile image url of t he user being enrolled as administrator
     * @return _nonce - the index of the new user added
     */
    function enrollAdmin(
        address _at,
        string memory _name,
        string memory _twitterId,
        string memory _imageUrl
    ) public virtual returns (uint256 _nonce);

    /**
     * Enroll yourself within the OrgToken
     * @dev should only be called if unenrolled!
     * @dev future state could digest a signature from an admin to approve them more securely
     *
     * @param _name - the user's name
     * @param _twitterId - the user's twitter ID (optional)
     * @param _imageUrl - the user's google profile image URL
     * @return _nonce - the nonce of the user within the contract
     */
    function enroll(
        string memory _name,
        string memory _twitterId,
        string memory _imageUrl
    ) public virtual returns (uint256 _nonce);

    /**
     * Promote a user to the Administrator role
     * @dev modifier onlyAdmin
     *
     * @param _user - the address being promoted to administrator
     */
    function promote(address _user) public virtual;

    /**
     * Change your own twitter id
     * @dev modifier onlyUser
     *
     * @param _twitterId - the truncated twitter id of the user (ex: mubcblockchain)
     */
    function setTwitterId(string memory _twitterId) public virtual;

    /**
     * Initialization function to set item contract address for permissions
     * @dev require item contract address == address (0)
     *
     * @param _at - the address of the item contract
     */
    function setItem(address _at) public virtual;

    /**
     * Add a new item to the user's inventory
     * @dev require item contract
     *
     * @param _user - the address being given an item
     * @param _item - the nonce of the item being added to the user's inventory
     * @param _value - the number of orgtokens to debit the user
     */
    function addItem(
        address _user,
        uint256 _item,
        uint256 _value
    ) public virtual;

    /**
     * Initialization function to set bounty contract address for permissions
     * @dev require bounty contract address == address (0)
     *
     * @param _at - the address of the bounty contract
     */
    function setBounty(address _at) public virtual;

    /**
     * Add a new bounty to the user's inventory
     * @dev require bounty contract
     *
     * @param _user - the address being given an bounty
     * @param _bounty - the nonce of the bounty being added to the user's inventory
     * @param _value - the number of orgtokens to award the user
     */
    function addBounty(
        address _user,
        uint256 _bounty,
        uint256 _value
    ) public virtual;

    /// VIEWABLE FUNCTIONS ///

    /**
     * Query an address for their role
     *
     * @param _user - the address being queried for user role
     * @return _role - uint code for their role
     *        0 = none; 1 = member, 2 = administrator
     */
    function role(address _user) public view virtual returns (uint256 _role);

    /**
     * Get the balance of a given user
     *
     * @param _user - the address being queried for orgtoken balance
     * @return _balance - the number of orgtokens owned by the account
     */
    function balanceOf(address _user)
        public
        view
        virtual
        returns (uint256 _balance);

    /**
     * Get the name of a given user
     *
     * @param _user - the address being queried for name
     * @return _name - the name text of the user
     */
    function name(address _user)
        public
        view
        virtual
        returns (string memory _name);

    /**
     * Return all user data for a given address if enrolled
     *
     * @param _user - the address being queried as a user
     * @return _name - user's name
     * @return _imageUrl -  user's google profile image
     * @return _twitterId - the twitterID, if set ("" otherwise)
     * @return _balance - user's org token balance
     * @return _role - user's on-chain permissions
     * @return _items - array of nonces of all items purchased by the user
     * @return _bounties - array of all bounties earned by the user
     * @return _at - address of the user
     */
    function getUser(address _user)
        public
        view
        virtual
        returns (
            string memory _name,
            string memory _imageUrl,
            string memory _twitterId,
            uint256 _balance,
            uint256 _role,
            uint256[] memory _items,
            uint256[] memory _bounties,
            address _at
        );

    /**
     * Return critical user data for all enrolled
     *
     * @return _nonce - the length of the arrays/ number of users
     * @return _names - array of all users' names
     * @return _imageUrls - array of all users' google profile image urls
     * @return _balances - array of all users' org token balances
     * @return _roles - array of all users' on-chain permissions
     * @return _ats - array of users' addresses
     */
    function getUsers()
        public
        view
        virtual
        returns (
            uint256 _nonce,
            string[] memory _names,
            string[] memory _imageUrls,
            uint256[] memory _balances,
            uint256[] memory _roles,
            address[] memory _ats
        );

    function getTwitterId(address _from)
        public
        view
        virtual
        returns (string memory _twitterid);

    /**
     * GSN Forwarder Call
     */
    function getTrustedForwarder() external view returns (address) {
        return trustedForwarder;
    }
}

enum Role {None, Member, Administrator}

struct User {
    string name;
    string twitterId;
    string imageUrl;
    address at;
    uint256 balance;
    Role role;
    uint256[] items;
    uint256[] bounties;
}
