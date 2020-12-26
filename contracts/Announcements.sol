//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract Announcements {
    event AnnouncementAdded(uint256 _nonce);
    event AnnouncementPinned(uint256 _nonce);

    uint256 public announcementNonce;
    uint256 public pinnedAnnouncement;
    mapping(uint256 => Announcement) announcements;

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
    ) public returns (uint256 _nonce) {
        announcementNonce = announcementNonce.add(1);
        Announcement storage announcement = announcements[announcementNonce];
        announcement.title = _title;
        announcement.body = _body;
        announcement.timecode = now;
        emit AnnouncementAdded(announcementNonce);
        if (_pin) pinAnnouncement(announcementNonce);
        return announcementNonce;
    }

    /**
     * Pin a specific announcement to the top of the UI
     * @dev modifier onlyAdmin
     *
     * @param _nonce - the index of the announcement to set as pinned within the contract
     */
    function pinAnnouncement(uint256 _nonce) public {
        pinnedAnnouncement = _nonce;
        emit AnnouncementPinned(_nonce);
    }

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
        public
        view
        returns (
            string memory _title,
            string memory _body,
            uint256 _timecode,
            bool _pinned
        )
    {
        Announcement memory announcement = announcements[_nonce];
        _title = announcement.title;
        _body = announcement.body;
        _timecode = announcement.timecode;
        _pinned = pinnedAnnouncement == _nonce;
    }

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
        returns (
            uint256 _nonce,
            string[] memory _titles,
            string[] memory _bodies,
            uint256[] memory _timecodes,
            uint256 _pinned
        )
    {
        _nonce = announcementNonce;
        _pinned = pinnedAnnouncement;
        for (uint i = 0; i < _nonce; i++) {
            _titles[i] = announcements[i].titles;
            _bodies[i] = announcements[i].bodies;
            _timecodes[i] = announcements[i].timecodes;
        }
    }
}

struct Announcement {
    string title;
    string body;
    uint256 timecode;
}
