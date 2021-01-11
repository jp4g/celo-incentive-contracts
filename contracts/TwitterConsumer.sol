pragma solidity >=0.4.22 <0.8.0;

import "./interfaces/ITwitterConsumer.sol";

contract TwitterConsumer is ITwitterConsumer {

    // // Map user address to twitter id
    // mapping (string => address) public twitterIdToAddress;

    // Limit 1 call per day for each user
    // mapping(address => string) public probation;

    // Map tweet id to user and determine whether or not they have retweeted
    // mapping(string => mapping(address => bool)) public hasRetweeted;


    // string public 
    /**
     * Network: Kovan
     * Oracle: Chainlink - 0x2f90A6D021db21e1B2A077c5a37B3C7E75D15b7e
     * Job ID: Chainlink - 29fa9aa13bf1468788b7cc4a500a45b8
     * Fee: 0.1 LINK
     */

    constructor(address _bountyAddress) public {
        setPublicChainlinkToken();
        oracle = 0x56dd6586DB0D08c6Ce7B2f2805af28616E082455;
        jobId = "0d85df2469284623a3469a7f2bab9ff2";
        fee = 0.1 * 10 ** 18; // 0.1 LINK
        bountyContract = IBounties(_bountyAddress);
        bountyContract.setConsumer(address(this));
    }

    function checkRetweets(string memory _userId, string memory _tweetId) public override returns (bytes32 requestId) {
        // Limit the number of calls that an account can make a day
        // require(now - probation[msg.sender] >= 1 days, "Probationary period has not expired.");

        // Ensure user can only verify a url once
        // require(!hasRetweeted[_url][msg.sender], "You have already retweeted this tweet")
        
        // If user does not exist in mapping then map address to id
        // if(twitterIdToAddress[_userId] == address(0)) {
        //     twitterIdToAddress[_userId] = msg.sender;
        // }
        
        // Get the Chainlink Request struct
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        
        request.add("userid", _userId);
        request.add("tweetid", _tweetId);

        
        // Call has completed and probationary period has commenced
        // probation[msg.sender] = now;

        emit OracleRequestMade(msg.sender, _tweetId);

        // Send Chainlink Request
        return sendChainlinkRequestTo(oracle, request, fee);
    }

    /**
     * Check if the specified user has retweeted
     */ 
    function fulfill(bytes32 _requestId, bool _status) public override recordChainlinkFulfillment(_requestId)
    {
        bountyContract.fulfillChainlinkRequest(_requestId, _status);
    }

}