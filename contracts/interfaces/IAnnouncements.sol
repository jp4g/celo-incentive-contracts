//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IUsers.sol";

abstract contract IAnnouncements {
    /// LIBRARIES ///
    using SafeMath for uint256;

    /// EVENTS ///
    event AnnouncementAdded(uint256 _nonce);
    event AnnouncementPinned(uint256 _nonce);

    /// MODIFIERS ///

    modifier onlyAdmin() {
        require(
            userContract.role(msg.sender) == 2,
            "Address not authenticated for this action"
        );
        _;
    }

    IUsers userContract;
    uint256 public announcementNonce;
    uint256 public pinnedAnnouncement;
    mapping(uint256 => Announcement) public announcements;

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
        string memory _title,
        string memory _body,
        bool _pin
    ) public virtual returns (uint256 _nonce);

    /**
     * Pin a specific announcement to the top of the UI
     * @dev modifier onlyAdmin
     *
     * @param _nonce - the index of the announcement to set as pinned within the contract
     */
    function pinAnnouncement(uint256 _nonce) public virtual;

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
        public
        view
        virtual
        returns (
            uint256 _nonce,
            string[] memory _titles,
            string[] memory _bodies,
            uint256[] memory _timecodes,
            uint256 _pinned
        );
}

struct Announcement {
    string title;
    string body;
    uint256 timecode;
}
