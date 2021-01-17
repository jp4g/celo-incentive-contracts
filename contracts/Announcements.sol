//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IAnnouncements.sol";

contract Announcements is IAnnouncements {
    //@param _users - the address of the deployed users contract
    constructor(address _users) public {
        userContract = IUsers(_users);
    }

    function pinAnnouncement(uint256 _nonce) public override onlyAdmin() {
        require(_nonce != 0, "Core: cannot set no pinned announcement!");
        require(
            pinnedAnnouncement != _nonce,
            "Core: Announcement already pinned!"
        );
        pinnedAnnouncement = _nonce;
        emit AnnouncementPinned(_nonce);
    }

    function addAnnouncement(
        string memory _title,
        string memory _body,
        bool _pin
    ) public override onlyAdmin() returns (uint256 _nonce) {
        announcementNonce = announcementNonce.add(1);
        Announcement storage announcement = announcements[announcementNonce];
        announcement.title = _title;
        announcement.body = _body;
        announcement.timecode = now;
        emit AnnouncementAdded(announcementNonce);
        if (_pin) pinAnnouncement(announcementNonce);
        return announcementNonce;
    }

    function getAnnouncements()
        public
        view
        override
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
        _titles = new string[](_nonce);
        _bodies = new string[](_nonce);
        _timecodes = new uint256[](_nonce);
        for (uint256 i = 0; i < _nonce; i++) {
            _titles[i] = announcements[i.add(1)].title;
            _bodies[i] = announcements[i.add(1)].body;
            _timecodes[i] = announcements[i.add(1)].timecode;
        }
    }
}
