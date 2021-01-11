pragma solidity >=0.4.22 <0.8.0;

import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "../interfaces/IBounties.sol";

abstract contract ITwitterConsumer is ChainlinkClient {
    
    /// VARIABLES ///
    IBounties bountyContract;
    address public oracle;
    bytes32 public jobId;
    uint256 public fee;

    /// EVENTS ///
    event OracleRequestMade(address caller, string tweetId);

    /// FUNCTIONS ///
    function checkRetweets(string memory _userId, string memory _tweetId) 
    public 
    virtual
    returns 
    (
        bytes32 requestId
    );

    function fulfill(bytes32 _requestId, bool _status) 
    public
    virtual;
}