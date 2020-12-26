//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import {Users, User, Role} from "../libraries/Users.sol";
import {Items, Item} from "../libraries/Items.sol";
import {Bounties, Bounty, Trigger} from "../libraries/Bounties.sol";

/**
 * Core contract used when interacting with OrgToken ecosystem
 */
abstract contract ICore {
    using SafeMath for uint256;
    using Users for User;
    using Items for Item;
    using Bounties for Bounty;

    /// EVENTS ///

    event UserEnrolled(address _user);
    event UserPromoted(address _user);
    event AnnouncementAdded(uint256 _nonce);
    event AnnouncementPinned(uint256 _nonce);
    event ItemAdded(uint256 _nonce);
    event ItemPurchased(uint256 _nonce, address _by);
    event ItemDelisted(uint256 _nonce);
    event BountyAdded(uint256 _nonce);
    event BountyApplication(uint256 _nonce, address _by);
    event BountyAwarded(uint256 _nonce, address _to);
    event BountyDelisted(uint256 _nonce);

    /// MODIFIERS ///

    modifier onlyAdmin() {
        require(
            users[msg.sender].role == Role.Administrator,
            "OrgCore Error: Caller is not an administrator!"
        );
        _;
    }

    modifier onlyUser() {
        require(
            users[msg.sender].role != Role.None,
            "OrgCore Error: Caller is not enrolled!"
        );
        _;
    }

    modifier sufficientBalance(uint256 _item) {
        require(
            users[msg.sender].balance >= items[_item].cost,
            "Insufficient OrgToken Balance for Item Transaction!"
        );
        _;
    }

    /// VARIABLES ///

    uint256 public userNonce;
    mapping(address => uint256) public userID;
    mapping(uint256 => User) public users;

    uint256 public announcementNonce;
    uint256 public pinnedAnnouncement;
    mapping(uint256 => Announcement) announcements;

    uint256 public itemNonce;
    mapping(uint256 => Item) items;

    /// USER FUNCTIONS ///

    /**
     * Enroll yourself within the OrgToken
     * @dev should only be called if unenrolled!
     *
     * @param _name - the user's name
     * @param _twitterId - the user's twitter ID
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
     * Return all data associated with a given user
     *
     * @param _user - the address of the user being queried
     * @return _name - the name of the user
     * @return _twitterId - the twitter id of the user
     * @return _imageUrl - the google profile image of the user
     * @return _balance - the number of orgtokens owned by the user
     * @return _role - the permissions given to the user's account on chain
     * @return _items - array of nonces of all items the user purchased
     * @return _bounties - array of nonces of all bounties awarded
     */
    function getUser(address _user)
        external
        virtual
        view
        returns (
            string memory _name,
            string memory _twitterId,
            string memory _imageUrl,
            uint256 _balance,
            uint256 _role,
            uint256[] _items,
            uint256[] _bounties
        );

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

    /// TOKEN FUNCTIONS ///

    /**
     * Credit Org Tokens to an account
     * @dev only used by bounty awarding
     *
     * @param _to - the address being credited with new tokens
     * @param _amount - the number of tokens to credit the account with
     * @return _balance - the new balance of _to post credit
     */
    function _credit(address _to, uint256 _amount)
        internal
        virtual
        returns (uint256 _balance);

    /**
     * Debit Org Tokens from an account
     * @dev only used by item purchasing
     *
     * @param _from - the address being debited tokens
     * @param _amount - the number of tokens to debit from the account
     * @return _balance - the new balance of _from post debit
     */
    function _debit(address _from, uint256 _amount)
        internal
        virtual
        returns (uint256 _balance);

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
     * Get all data regarding a specific announcement
     *
     * @param _nonce - the index of the announcement to query internally
     * @return _title - the title text of the announcement post
     * @return _body - the body text of the announcement post
     * @return _timecode - UNIX timestamp on Ethereum when the announcement was committed
     * @return _pinned - true if the announcement is pinned, false otherwise
     */
    function getAnnouncement(uint256 _nonce)
        external
        virtual
        view
        returns (
            string memory _title,
            string memory _body,
            uint256 _timecode,
            bool _pinned
        );

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
    function delistItem(uint _nonce) external virtual;

    /**
     * Get all data associated with an item
     *
     * @param _nonce - the index of the item on-chain
     * @return _title - the title text of the item
     * @return _description - the description text of the item
     * @return _imageUrl - the s3 bucket url of the image
     * @return _cost - the OrgToken cost to purchase the token
     * @return _infinite - true if the item is infinitely in stock, and false otherwise
     * @return _quantity - remaining items in stock for purchase (if _infinite == false)
     * @return _active - true if the item can be purchased currently, and false otherwise
     * @return _owners - array of addresses of all users who have purchased this item
     */
    function getItem(uint256 _nonce) external virtual view returns (
        string memory _title,
        string memory _description,
        string memory _imageUrl,
        uint _cost,
        bool _infinite,
        uint _quantity,
        bool _active,
        address[] memory _owners
    );

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
    function getItems() external virtual view returns (
        uint _itemNonce,
        string[] memory _titles,
        string[] memory _descriptions,
        string[] memory _imageUrls,
        uint[] memory _costs,
        bool[] memory _infinites,
        uint[] memory _quantities,
        bool[] memory _actives
    );

    /// BOUNTY FUNCTIONS ///
}

struct Announcement {
    string title;
    string body;
    uint256 timecode;
}
