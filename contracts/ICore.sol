//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * Interface for main contract used when interacting with OrgToken ecosystem
 */
abstract contract ICore {
    using SafeMath for uint256;

    /// EVENTS ///

    event UserEnrolled(address _user);
    event UserPromoted(address _user);
    event TwitterIDUpdated(address _user);
    event AnnouncementAdded(uint256 _nonce);
    event AnnouncementPinned(uint256 _nonce);
    event ItemAdded(uint256 _nonce);
    event ItemPurchased(uint256 _nonce, address _by, uint256 _burned);
    event ItemDelisted(uint256 _nonce);
    event BountyAdded(uint256 _nonce);
    event BountyApplication(uint256 _nonce, address _by);
    event BountyAwarded(uint256 _nonce, address _to, uint256 _minted);
    event BountyRejected(uint256 _nonce, address _to);
    event BountyDelisted(uint256 _nonce);

    /// MODIFIERS ///

    modifier onlyAdmin() {
        require(
            users[userID[msg.sender]].role == Role.Administrator,
            "Caller is not an administrator"
        );
        _;
    }

    modifier onlyUser() {
        require(
            users[userID[msg.sender]].role != Role.None,
            "OrgCore Error: Caller is not enrolled!"
        );
        _;
    }

    modifier beforeItemBuy(uint256 _item) {
        require(items[_item].active, "Item not for sale");
        require(
            items[_item].infinite || items[_item].quantity > 0,
            "Item not in stock"
        );
        require(
            users[userID[msg.sender]].balance >= items[_item].cost,
            "User has insufficient balance"
        );
        require(!items[_item].purchased[msg.sender], "User already owns item");
        _;
    }

    modifier beforeBountyApp(uint256 _bounty) {
        require(
            bounties[_bounty].infinite || bounties[_bounty].quantity > 0,
            "Bounty not in stock"
        );
        require(
            bounties[_bounty].active,
            "Bounty not available for application"
        );
        require(
            tempban[_bounty][msg.sender] < now.sub(1 days),
            "Tempbanned < 24 hours ago"
        );
        require(
            bounties[_bounty].status[msg.sender] != BountyState.Awarded,
            "User has has bounty"
        );
        require(
            bounties[_bounty].status[msg.sender] != BountyState.Pending,
            "User has pending approval"
        );
        _;
    }
    /// VARIABLES ///

    uint256 public userNonce;
    mapping(address => uint256) public userID;
    mapping(uint256 => User) public users;

    uint256 public announcementNonce;
    uint256 public pinnedAnnouncement;
    mapping(uint256 => Announcement) public announcements;

    uint256 public itemNonce;
    mapping(uint256 => Item) public items;

    uint256 public bountyNonce;
    mapping(uint256 => Bounty) public bounties;
    mapping(uint256 => uint256) pendingNonces;
    mapping(uint256 => mapping(uint256 => Pending)) pendings;
    mapping(uint256 => mapping(address => uint256)) tempban;

    uint256 constant NUM_TRIGGERS = 2;

    /// USER FUNCTIONS ///

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
        string calldata _name,
        string calldata _twitterId,
        string calldata _imageUrl
    ) external virtual returns (uint256 _nonce);

    /**
     * Promote a user to the Administrator role
     * @dev modifier onlyAdmin
     *
     * @param _user - the address being promoted to administrator
     */
    function promote(address _user) external virtual;

    /**
     * Change your own twitter id
     * @dev modifier onlyUser
     *
     * @param _twitterId - the truncated twitter id of the user (ex: mubcblockchain)
     */
    function setTwitterId(string calldata _twitterId) external virtual;

    /**
     * Return critical user data for all enrolled
     *
     * @return _nonce - the length of the arrays/ number of users
     * @return _names - array of all users' names
     * @return _imageUrls - array of all users' google profile image urls
     * @return _balances - array of all users' org token balances
     * @return _roles - array of all users' on-chain permissions
     */
    function getUsers()
        external
        virtual
        view
        returns (
            uint256 _nonce,
            string[] memory _names,
            string[] memory _imageUrls,
            uint256[] memory _balances,
            uint256[] memory _roles
        );

    /// ANNOUNCEMENT FUNCTIONS ///

    /**
     * Add a new announcement
     * @dev modifier onlyAdmin
     *
     * @param _title - the title text of the announcement post
     * @param _body - the body text of the announcement post
     * @param _pin - true if post should is pinned to the top of the UI, false otherwise
     * @return _nonce - the nonce of the announcement on-chain
     */
    function addAnnouncement(
        string calldata _title,
        string calldata _body,
        bool _pin
    ) external virtual returns (uint256 _nonce);

    /**
     * Pin a specific announcement to the top of the UI
     * @dev modifier onlyAdmin
     *
     * @param _nonce - the index of the announcement to set as pinned within the contract
     */
    function pinAnnouncement(uint256 _nonce) external virtual;

    /**
     * Get every announcement added to the platform
     *
     * @return _nonce - the number of announcements returned
     * @return _titles - array of all announcements' title text
     * @return _bodies - array of all announcements' body text
     * @return _timecodes - array of all announcements' UNIX timestamps
     * @return _pinned - nonce of pinned announcement
     */
    function getAnnouncements()
        external
        virtual
        view
        returns (
            uint256 _nonce,
            string[] memory _titles,
            string[] memory _bodies,
            uint256[] memory _timecodes,
            uint256 _pinned
        );

    /// ITEM FUNCTIONS ///

    /**
     * List a new item for purchase
     * @dev modifier onlyAdmin
     *
     * @param _title - the title text for the item
     * @param _description - the body text for the item
     * @param _imageUrl - the s3 bucket url for the item's image
     * @param _cost - the number of orgtokens to charge for this item
     * @param _infinite - true if the item should be infinitely purchasable, false otherwise
     * @param _quantity - number of times the item can be sold (if _infinite == false)
     * @return _nonce - the index of the item on-chain
     */
    function addItem(
        string calldata _title,
        string calldata _description,
        string calldata _imageUrl,
        uint256 _cost,
        bool _infinite,
        uint256 _quantity
    ) external virtual returns (uint256 _nonce);

    /**
     * Purchase an item
     * @dev modifier onlyUser, sufficientBalance
     *
     * @param _nonce - the index of the item being purchased
     * @return _balance - the orgtoken balance of the caller after the purchase
     */
    function buyItem(uint256 _nonce)
        external
        virtual
        returns (uint256 _balance);

    /**
     * Delist an item for purchase
     * @dev modifier onlyAdmin
     *
     * @param _nonce - the index of the item to delist
     */
    function delistItem(uint256 _nonce) external virtual;

    /**
     * Get critical data on every item on-chain
     *
     * @return _itemNonce - the number of items returned/ on the contract
     * @return _titles - array of items' title text
     * @return _descriptions - array of items' description text
     * @return _imageUrls - array of items' s3 image urls
     * @return _costs - array of items' OrgToken cost of purchase
     * @return _infinites - array of infinite-in-stock true or false field
     * @return _quantities - array of items' stock quanitities (if not infinite)
     * @return _actives - array of items' active listing state in true or false
     */
    function getItems()
        external
        virtual
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
        );

    /// BOUNTY FUNCTIONS ///

    function addBounty(
        string calldata _title,
        string calldata _description,
        string calldata _imageUrl,
        uint256 _award,
        bool _infinite,
        uint256 _quantity,
        string calldata _tweetId
    ) external virtual returns (uint256 _nonce);

    function applyForBounty(uint256 _nonce) external virtual;

    function approveBountyRequest(uint256 _trigger, uint256 _nonce)
        external
        virtual;

    function rejectBountyRequest(uint256 _trigger, uint256 _nonce)
        external
        virtual;

    /**
     * Remove a bounty from active circulation, meaning it is no longer accessible
     * @dev modifier onlyAdmin
     *
     * @param _nonce - the index of the bounty within the contract
     */
    function delistBounty(uint256 _nonce) external virtual;

    /**
     * Return all pending bounty approval requests
     *
     * @param _trigger - trigger type to query (1 = manual, 2 = retweet)
     * @return _nonce - the number of pending bounty requests
     * @return _users - array of all users with pending requests for bounties
     * @return _bounties - array of all bounties being requested by a user
     * @dev pending request x is found doing _users[x] and _bounties[x]
     */
    function pendingBountyRequests(uint256 _trigger)
        external
        virtual
        view
        returns (
            uint256 _nonce,
            address[] memory _users,
            uint256[] memory _bounties
        );

    /**
     * Get summary data on all bounties
     *
     * @return _bountyNonce - the number of bounties returned/ on the contract
     * @return _titles - array of bounties' title text
     * @return _descriptions - array of bounties' description text
     * @return _imageUrls - array of bounties' s3 image urls
     * @return _awards - array of bounties' OrgToken cost of purchase
     * @return _infinites - array of infinite-in-stock true or false field
     * @return _quantities - array of bounties' stock quanitities (if not infinite)
     * @return _actives - array of bounties' active listing state in true or false
     * @return _manuals - array of true-if-manual and false-if-retweet values for bounties
     */
    function getBounties()
        external
        virtual
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
        );
}

/// SCHEMA ///

enum Role {None, Member, Administrator}
enum BountyState {None, Pending, Awarded}
enum Trigger {None, Manual, Twitter}

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

struct Announcement {
    string title;
    string body;
    uint256 timecode;
}

struct Item {
    string title;
    string description;
    string imageUrl;
    uint256 cost;
    bool infinite;
    uint256 quantity;
    bool active;
    mapping(address => bool) purchased;
    address[] owners;
}

struct Bounty {
    string name;
    string description;
    string imageUrl;
    uint256 award;
    bool infinite;
    uint256 quantity;
    bool active;
    Trigger trigger;
    string tweet;
    uint256 pendingNonce;
    mapping(address => BountyState) status;
    address[] holders;
}

struct Pending {
    address user;
    uint256 bounty;
}
