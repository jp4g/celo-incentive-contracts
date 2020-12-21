//SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.6.0 < 0.8.0;
pragma experimental ABIEncoderV2;

import '@opengsn/gsn/contracts/BaseRelayRecipient.sol';

/**
 * Core contract used when interacting with OrgToken ecosystem
 */
abstract contract IOrgCore is BaseRelayRecipient {

    /// VARIABLES ///
    
    mapping(address => User) users;
    
    /// MODIFIERS ///

    modifier onlyAdmin() {
        require(
            users[_msgSender()].role == Role.Administrator,
            "OrgCore Error: Caller is not an administrator!"
        );
        _;
    }

    /**
     * Allow if a contract caller is a user, and reject otherwise
     */
    modifier onlyUser() {
        require(users[_msgSender()].role != Role.None, "OrgCore Error: Caller is not enrolled!");
        _;
    }

    /// MUTABLE FUNCTIONS ///

    /**
     * Mint new OrgTokens to an address
     * @dev modifier onlyAdmin
     *
     * @param _to - the address recieving new OrgTokens
     * @param _value - the balance of OrgTokens to credit the address with
     * @return the current balance of _to
     */
    function mint(address _to, uint _value) external virtual returns (uint);

    /**
     * Enroll yourself within the OrgToken
     * @dev should only be called if unenrolled!
     */
    function enroll(string calldata uuid, string calldata twitter) external virtual;

    /// VIEWABLE FUNCTIONS ///


}

struct User {
    string uuid;
    string twitter;
    Role role;
    uint balance;
}

enum Role { None, Member, Administrator }