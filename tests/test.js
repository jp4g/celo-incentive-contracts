/**
 * OrgToken Test Suite
 * @author Miami University Blockchain Club
 * @date 12.29.2020
 */

let { expect } = require('chai')
let { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers')
let OrgToken = artifacts.require('./Core')
const time = require('./time');

contract('OrgToken Unit Testing', (accounts) => {

    let admin1 = accounts[0]
    let admin2 = accounts[1]
    let member1 = accounts[2]
    let member2 = accounts[3]
    let instance

    before(async () => {
       instance = await OrgToken.deployed()
    })

    describe("User Functionality", async () => {
        it('User can self enroll', async () => {
            let { logs } = await instance.enroll("admin 2", "twitterID-admin2", "URL-admin2", { from: admin2 })
            expectEvent.inLogs(logs, 'UserEnrolled', {_user: admin2})
        })

        it('User cannot re-enroll self', async () => {
            await expectRevert(
                instance.enroll("admin 2", "twitterID-admin2", "URL-admin2", { from: admin2 }),
                "Core: User Already Enrolled!"
            )
        })

        it('Admin can promote a user to admin', async () => {
            await expectRevert(
                instance.promote(admin2, { from: admin2 }),
                "Caller is not an administrator"
            )
            let { logs } = await instance.promote(admin2, { from: admin1 })
            expectEvent.inLogs(logs, 'UserPromoted', { _user: admin2 })
        })

        it('User can change their twitterID', async () => {
            await expectRevert(
                instance.setTwitterId('', { from: admin2 }),
                "Core: Must set twitter ID to non-null value!"
            )
            let { logs } = await instance.setTwitterId('changed-id', { from: admin2 })
            expectEvent.inLogs(logs, 'TwitterIDUpdated', { _user: admin2 })
        })

        it('Can view all data for a single user', async () => {
            let userId = await instance.userID(admin2)
            let data = await instance.users(userId)
            expect(data.name).to.be.equal('admin 2')
        })

        it('Can view summary data on all users', async () => {
            await instance.enroll("member1", "twitterID-member1", "URL-member1", { from: member1 })
            await instance.enroll("member2", "twitterID-member2", "URL-member2", { from: member2 })
            let data = await instance.getUsers()
            let nonce = data._nonce.toNumber()
            for (let i = 0; i < nonce; i++)
                console.log(`\nUser #${i}: ${data._names[i]} (Role: ${data._roles[i]})`)      
            let member2URL = data._imageUrls[3]
            let member1Name = data._names[2]
            expect(member2URL).to.be.equal('URL-member2')
            expect(member1Name).to.be.equal('member1')
        })
    })

    describe("Announcement Functionality", async () => {
        it('onlyAdmin() for all announcement state mutations', async () => {
            await expectRevert(
                instance.addAnnouncement('Title1', 'Body1', true, { from: member2 }),
                "Caller is not an administrator"
            )
            await expectRevert(
                instance.pinAnnouncement(1, { from: member2 }),
                "Caller is not an administrator"
            )
        })

        it('Add announcement without pinning', async () => {
            let { logs } = await instance.addAnnouncement(
                'Unpinned Title',
                'Unpinned Body',
                false,
                { from: admin1 }
            )
            expectEvent.inLogs(logs, 'AnnouncementAdded', { _nonce: new BN(1) })
            let pinned = await instance.pinnedAnnouncement();
            expect(pinned.toNumber()).to.be.not.equal(1)
        })

        it('Add announcement and pin', async () => {
            let { logs } = await instance.addAnnouncement(
                'Pinned Title',
                'Pinned Body',
                true,
                { from: admin1 }
            )
            expectEvent.inLogs(logs, 'AnnouncementAdded', { _nonce: new BN(2) })
            expectEvent.inLogs(logs, 'AnnouncementPinned', { _nonce: new BN(2) })
            let pinned = await instance.pinnedAnnouncement();
            expect(pinned.toNumber()).to.be.equal(2)
        })

        it('Pin an existing announcement', async () => {
            let { logs } = await instance.pinAnnouncement(1)
            expectEvent.inLogs(logs, 'AnnouncementPinned', { _nonce: new BN(1) })
        })    
        it('Cannot pin already pinned announcement or no announcement', async () => {
            await expectRevert(
                instance.pinAnnouncement(0),
                "Core: cannot set no pinned announcement!"
            )
            await expectRevert(
                instance.pinAnnouncement(1),
                "Core: Announcement already pinned!"
            )
        })
        it('Return data for all announcements', async () => {
            await instance.addAnnouncement('Title3', 'Body3', true, { from: admin1 })
            let data = await instance.getAnnouncements()
            let nonce = await data._nonce.toNumber()
            console.log("Pinned Announcement: ", data._pinned.toNumber())
            for (let i = 0; i < nonce; i++) 
                console.log(`Announcement #${i+1} - Title: ${data._titles[i]}; Body: ${data._bodies[i]}`)
            expect(data._titles[1]).to.be.equal('Pinned Title')
            expect(data._bodies[2]).to.be.equal('Body3')
            expect(data._pinned.toNumber()).to.be.equal(nonce)
        })
    })

    describe("Item Functionality", async () => {
        it('Admin can add a new infinite item', async () => {
            await instance.addItem("Title", "Body", "URL", 10, true, 0, { from: admin1 })
            let data = await instance.items(1)
            console.log(data)
        })
        it('Admin can add a new finite item', async () => {

        })
        it('Admin can delist an item', async () => {

        })
        it('Items that are inactive cannot be purchased', async () => {

        })
        it('Users with sufficient balance can buy items', async () => {

        })
        it('Users without sufficient balance cannot buy items', async () => {

        })
        it('Finite items can run out of stock & become unobtainable', async () => {

        })
        it('Return data for all items', async () => {

        })
    })

    describe("Bounty Functionality", async () => {
        it('Admin can add a new infinite manual bounty', async () => {
            let { logs } = await instance.addBounty(
                'bounty1-title',
                'bounty1-description',
                'bounty1-url',
                100,
                true,
                0,
                "",
                { from: admin1 }
            )
            let bountyNonce = new BN(1)
            expectEvent.inLogs(logs, 'BountyAdded', { _nonce: bountyNonce })
            await instance.applyForBounty(bountyNonce, { from: member1 })
            await instance.approveBountyRequest(1, 1, { from: admin1 });
            let data = await instance.getBounty(1)
            expect(data._title).to.be.equal('bounty1-title')
            expect(data._holders[0]).to.be.equal(member1)
            expect(data._infinite && data._active && data._manual).to.be.true
        })
        it('Admin can add a new finite bounty', async () => {
            let { logs } = await instance.addBounty(
                'bounty2-title',
                'bounty2-description',
                'bounty2-url',
                100,
                false,
                1,
                "",
                { from: admin1 }
            )
            let bountyNonce = new BN(2)
            let data = await instance.getBounty(bountyNonce)
            expect(data._quantity.toNumber()).to.be.equal(1)
            expectEvent.inLogs(logs, 'BountyAdded', { _nonce: bountyNonce })
            await instance.applyForBounty(bountyNonce, { from: member1 })
            await instance.approveBountyRequest(1, 1, { from: admin1 });
            await expectRevert(
                instance.applyForBounty(bountyNonce, { from: member2 }),
                "Bounty not in stock"
            )
            data = await instance.getBounty(bountyNonce)
            expect(data._title).to.be.equal('bounty2-title')
            expect(data._holders[0]).to.be.equal(member1)
            expect(!data._infinite && !data._active && data._manual).to.be.true
            expect(data._quantity.toNumber()).to.be.equal(0)
        })
        it('Only admin can list a bounty', async () => {
            await expectRevert(
                instance.addBounty(
                    'revert-title',
                    'revert-description',
                    'revert-url',
                    100,
                    false,
                    1,
                    "",
                    { from: member2 }
                ),
                "Caller is not an administrator"
            )
        })
        it('Admin can delist a bounty', async () => {
            let { logs } = await instance.addBounty(
                'bounty3-title',
                'bounty3-description',
                'bounty3-url',
                100,
                false,
                1,
                "",
                { from: admin1 }
            )
            let bountyNonce = new BN(3)
            let data = await instance.getBounty(bountyNonce)
            expect(data._active).to.be.true
            await instance.delistBounty(bountyNonce, { from: admin1})
            await expectRevert(
                instance.applyForBounty(bountyNonce, { from: member1 }),
                "Bounty not available for application"
            )
            data = await instance.getBounty(bountyNonce)
            expect(data._active).to.be.false
        })

        it('Users can apply for bounties', async () => {
            let { logs } = await instance.addBounty(
                'bounty4-title',
                'bounty4-description',
                'bounty4-url',
                100,
                false,
                5,
                "",
                { from: admin1 }
            )
            let bountyNonce = new BN(4)
            await instance.applyForBounty(bountyNonce, { from: member1 })
            await instance.applyForBounty(bountyNonce, { from: member2 })
            await expectRevert(
                instance.applyForBounty(bountyNonce, { from: member1 }),
                "User has pending approval"
            )
            let data = await instance.pendingBountyRequests(1)
            expect(data._nonce.toNumber()).to.be.equal(2)
            expect(data._users[0]).to.be.equal(member1)
            expect(data._bounties[1]).to.be.bignumber.equal(bountyNonce)
        })
        it('Admin can accept or manually accept or reject requests for approval', async () => {
            let bountyNonce = new BN(4)
            let oldBalance = (await instance.users(member1)).balance.toNumber()
            let { logs } = await instance.approveBountyRequest(1, 1, { from: admin1 })
            expectEvent.inLogs(
                logs,
                'BountyAwarded',
                { _nonce: bountyNonce, _to: member1,  _minted: new BN(100)}
            )
            await expectRevert(
                instance.applyForBounty(bountyNonce, { from: member1 }),
                "User has has bounty"
            )
            let userId = await instance.userID(member1)
            let user = await instance.users(userId)
            console.log("FLAGGG", user)
            let bounties = user.bounties.map(bounty => bounty.toNumber())
            expect(user.balance.toNumber()).to.be.equal(oldBalance + 100)
            expect(bounties.includes(bountyNonce.toNumber())).to.be.true
            await instance.rejectBountyRequest(1, 1, { from: admin1 })
        })
        it('Users rejected from bounty application are blacklisted from the bounty for 24 hours', async () => {
            console.log(await instance.pendingBountyRequests(1))
            let bountyNonce = new BN(4)
            await expectRevert(
                instance.applyForBounty(bountyNonce, { from: member2 }),
                "Tempbanned < 24 hours ago"
            )
            // await time.increase(time.duration.days(1))
            // let { logs } = await instance.applyForBounty(bountyNonce, { from: member2 })
            // expectEvent.inLogs(logs, "BountyApplication", { _nonce: bountyNonce, _by: member2 })
        })
        it('Users can autonomously award bounties with Twitter Chainlink approval', async () => {
            //@dev todo
            expect(false).to.be.true
        })
    })
})