//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@opengsn/gsn/contracts/BasePaymaster.sol";

contract OrgTokenPaymaster is BasePaymaster {
    address public users;
    address public announcements;
    address public items;
    address public bounties;

    // allow the owner to set target contracts
    event TargetsSet(
        address _users,
        address _announcements,
        address _items,
        address _bounties
    );

    /**
     * Set the target contracts for this paymaster
     *
     * @param _users - the address of the users contract
     * @param _announcements - the address of the announcements contract
     * @param _items - the address of the items contract
     * @param _bounties - the address of the bounties contract
     */
    function setTargets(
        address _users,
        address _announcements,
        address _items,
        address _bounties
    ) external onlyOwner {
        users = _users;
        announcements = _announcements;
        items = _items;
        bounties = _bounties;
        emit TargetsSet(users, announcements, items, bounties);
    }

    event PreRelayed(uint256);
    event PostRelayed(uint256);

    function preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleGas
    ) external virtual override returns (bytes memory context, bool) {
        _verifyForwarder(relayRequest);
        (signature, approvalData, maxPossibleGas);
        address _to = relayRequest.request.to;
        bool accept = _to == users || _to == announcements || _to == items || _to == bounties;
        require(accept);
        emit PreRelayed(now);
        return (abi.encode(now), false);
    }

    function postRelayedCall(
        bytes calldata context,
        bool success,
        uint256 gasUseWithoutPost,
        GsnTypes.RelayData calldata relayData
    ) external virtual override {
        (context, success, gasUseWithoutPost, relayData);
        emit PostRelayed(abi.decode(context, (uint256)));
    }

    function versionPaymaster()
        external
        view
        virtual
        override
        returns (string memory)
    {
        return "2.0.0";
    }
}
