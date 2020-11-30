pragma solidity >= 0.7.0 < 0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @author Miami University Blockchain Club
 * Date: 11.29.20
 *
 * Authentication for OrgToken Ecosystem
 */
contract Auth {

    using SafeMath for uint256;

    event Enrolled(address _account);

    uint userNonce;
    mapping(uint => address) users;
    mapping(address => uint) permissions;

    modifier onlyAdmin() {
        require(
            permissions[msg.sender] == uint(UserType.Administrator),
            "Auth Error:Must be administrator!");
        _;
    }

    constructor() {
        permissions[msg.sender] = uint(UserType.Administrator);
        userNonce = userNonce.add(1);
        users[userNonce] = msg.sender;
        emit Enrolled(msg.sender);
    }

    /**
     * Enroll a new user within the dApp
     * @param _account - the ethereum address being enrolled in the dApp
     * @param _role = 
     */
    function enroll(address _account, uint _role) public onlyAdmin {
        require(permissions[_account] == uint(UserType.None), "Auth Error: Address already enrolled!");
        permissions[_account] = _role;
        userNonce = userNonce.add(1);
        users[userNonce] = _account;
        emit Enrolled(_account);
    }

    /**
     * Determine the permission level of a given address
     * @param _account - the ethereum address being queried for permission level
     * @return _role - the permission level of the address
     */
    function isEnrolled(address _account) public view returns (uint _role) {
        return permissions[_account];
    }
}

enum UserType {None, User, Administrator}