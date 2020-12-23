//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/math/SafeMath.sol';
import { Users, User, Role } from '../libraries/Users.sol';


/**
 * Core contract used when interacting with OrgToken ecosystem
 */
abstract contract ICore {

    using SafeMath for uint256;
    using Users for User;

    /// EVENTS ///

    event UserEnrolled(address _user);
    event UserPromoted(address _user);
    event AnnouncementAdded(uint _nonce);
    event AnnouncementPinned(uint _nonce);
    event ItemAdded(uint _nonce);
    event ItemPurchased(uint _nonce, address _by);
    event ItemDelisted(uint _nonce);
    event BountyAdded(uint _nonce);
    event BountyApplication(uint _nonce, address _by);
    event BountyAwarded(uint _nonce, address _to);
    event BountyDelisted(uint _nonce);

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

    /// VARIABLES ///

    uint256 public userNonce;
    mapping(address => uint256) public userID;
    mapping(uint256 => User) public users;

    uint256 public announcementNonce;
    uint256 public pinnedAnnouncement;
    mapping(uint256 => Announcement) announcements;

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
    function getUser(address _user) external virtual view returns (
        string memory _name,
        string memory _twitterId,
        string memory _imageUrl,
        uint _balance,
        uint _role,
        uint[] _items,
        uint[] _bounties
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
    function getUsers() external virtual view returns (
        uint _nonce,
        string[] memory _names,
        string[] memory _imageUrls,
        uint[] memory _balances,
        uint[] memory _roles
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
    function _credit(address _to, uint _amount) internal virtual returns (uint _balance);

    /**
     * Debit Org Tokens from an account
     * @dev only used by item purchasing
     *
     * @param _from - the address being debited tokens
     * @param _amount - the number of tokens to debit from the account
     * @return _balance - the new balance of _from post debit
     */
    function _debit(address _from, uint _amount) internal virtual returns (uint _balance);

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
    function getAnnouncement(uint256 _nonce) external virtual view returns (
        string memory _title,
        string memory _body,
        uint _timecode,
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
    function getAnnouncements() external virtual view returns (
        uint _nonce,
        string[] memory _titles,
        string[] memory _bodies,
        uint[] memory _timecodes,
        uint _pinned
    );

    /// ITEM FUNCTIONS ///

    /// BOUNTY FUNCTIONS ///
}

struct Announcement {
    string title;
    string body;
    uint timecode;
}