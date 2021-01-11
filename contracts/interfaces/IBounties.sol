//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IUsers.sol";
import "../interfaces/ITwitterConsumer.sol";

abstract contract IBounties {
    /// LIBRARIES ///

    using SafeMath for uint256;

    /// EVENTS ///

    event BountyAdded(uint256 _nonce);
    event BountyApplication(uint256 _nonce, address _by);
    event BountyAwarded(uint256 _nonce, address _to, uint256 _minted);
    event BountyRejected(uint256 _nonce, address _to);
    event BountyDelisted(uint256 _nonce);
    event FLAG(bool _infinite);

    /// MODIFIERS ///

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

    modifier onlyAdmin() {
        require(
            userContract.role(msg.sender) == 2,
            "Address not authenticated for this action"
        );
        _;
    }

    /// VARIABLES ///
    IUsers userContract;
    ITwitterConsumer consumerInstance;
    address public consumerContract;
    uint256 public bountyNonce;
    uint256 public requestNonce;
    mapping(uint256 => Bounty) public bounties; //bounty nonce to bounty struct
    mapping(uint256 => Request) public requests; //request nonce to request struct
    mapping(uint256 => uint256) pendingIndices; //trigger enum to pending requests for that trigger
    mapping(uint256 => mapping(uint256 => uint256)) pendingRequests; //trigger to pending index to request nonce
    mapping(uint256 => mapping(address => uint256)) tempban; //bounty nonce to user to timecode of ban
    mapping(bytes32 => uint256) chainlinkRequests; //chainlink request to request nonce
    mapping(string => mapping(string => bool)) hasRetweeted;

    /// MUTABLE FUNCTIONS ///

    /**
     * Initialization function to set consumer contract address for permissions
     * @dev require consumer contract address == address (0)
     *
     * @param _at - the address of the consumer contract
     */
    function setConsumer(address _at) public virtual;

    /**
     * Add a new bounty to the chain
     * @dev modifier onlyAdmin
     *
     * @param _title - the title text of the bounty
     * @param _description - the description text of the bounty
     * @param _imageUrl - the s3 image url of the bounty
     * @param _award - the number of org tokens to mint to a user for completing the bounty
     * @param _infinite - true if bounty can be awarded unlimited number of times, false otherwise
     * @param _quantity - the number of times a bounty can be claimed. overridden by _infinite
     * @param _manual - true if admin approves bounties, false otherwise.
     * @param _tweetId - if the bounty is triggered by retweets, specify id. overridden by _manual.
     */
    function addBounty(
        string memory _title,
        string memory _description,
        string memory _imageUrl,
        uint256 _award,
        bool _infinite,
        uint256 _quantity,
        bool _manual,
        string memory _tweetId
    ) public virtual returns (uint256 _nonce);

    /**
     * Make a new application for a bounty as a user
     * @dev modifier beforeBountyApp
     *
     * @param _nonce - the index of the bounty being applied to
     */
    function applyForBounty(uint256 _nonce) public virtual;

    /**
     * Approve a bounty request and dispense award to user
     * @dev modifier onlyAdmin
     *
     * @param _trigger - uint code of the bounty trigger type
     * @param _index - index of the bounty request
     */
    function approveBountyRequest(uint256 _trigger, uint256 _index)
        public
        virtual;

    /**
     * Reject a bounty request
     * @dev modifier onlyAdmin
     *
     * @param _trigger - uint code of the bounty trigger type
     * @param _index - index of the bounty request
     */
    function rejectBountyRequest(uint256 _trigger, uint256 _index)
        public
        virtual;

    /**
     * Remove a bounty from active circulation, meaning it is no longer accessible
     * @dev modifier onlyAdmin
     *
     * @param _nonce - the index of the bounty within the contract
     */
    function delistBounty(uint256 _nonce) public virtual;

    /**
     * Function is called when a Chainlink request is fufilled
     *
     * @param _requestId - The id of the Chainlink request that is completed
     * @param _status - The status that resolves to whether or not the user has retweeted a particular tweet
     *
     */
    function fufillChainlinkRequest(bytes32 _requestId, bool _status)
        public
        virtual;

    /// VIEWABLE FUNCTIONS ///

    /**
     * Return all pending bounty approval requests
     *
     * @param _trigger - trigger type to query (1 = manual, 2 = retweet)
     * @return _nonce - the number of pending bounty requests
     * @return _users - array of all users with pending requests for bounties
     * @return _userNames
     * @return _bounties - array of all bounties being requested by a user
     * @return _bountyNames 
     * @dev pending request x is found doing _users[x] and _bounties[x]
     */
    function pendingBountyRequests(uint256 _trigger)
        public
        view
        virtual
        returns (
            uint256 _nonce,
            address[] memory _users,
            string[] memory _userNames,
            uint256[] memory _bounties,
            string[] memory _bountyNames
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
        public
        view
        virtual
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

    /**
     * Function determines if a user has rewteeted a tweet or not
     *
     * @param _userid - The id of the Chainlink request that is completed
     * @param _tweet - The status that resolves to whether or not the user has retweeted a particular tweet
     *
     */
    function checkRetweet(string memory _userid, string memory _tweet)
        public
        view
        virtual
        returns (bool);

    /**
     * Function determines if a Chainlink request has been fufilled or not
     *
     * @param _requestId - The requestId of the chainlink job
     *
     */
    function checkFufillment(bytes32 _requestId) public view virtual returns (bool);
}

enum BountyState {None, Pending, Awarded}
enum Trigger {None, Manual, Twitter}

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
    uint256 pendingIndex;
    mapping(address => BountyState) status;
    address[] holders;
}

struct Request {
    address user;
    uint256 bounty;
    uint256 pendingIndex;
    bool fulfilled;
}
