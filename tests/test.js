/**
 * OrgToken Test Suite
 * @author Miami University Blockchain Club
 * @date 12.29.2020
 */

let { expect } = require('chai')
let { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers')
let UsersContract = artifacts.require('./Users')
let AnnouncementsContract = artifacts.require('./Announcements')
let ItemsContract = artifacts.require('./Items')
let BountiesContract = artifacts.require('./Bounties')
let ConsumerContract = artifacts.require('./TwitterConsumer')
const time = require('./time')

const sleep = (ms) => {
    return new Promise(resolve => setTimeout(resolve, ms));
}


contract('OrgToken Unit Testing', (accounts) => {

    let admin1 = accounts[0]
    let admin2 = accounts[1]
    let member1 = accounts[2]
    let member2 = accounts[3]
    let member3 = accounts[4]
    let validTwitterMember1 = accounts[5]
    let validTwitterMember2 = accounts[6]
    let users, announcements, items, bounties, consumer

    before(async () => {
        users = await UsersContract.deployed()
        announcements = await AnnouncementsContract.deployed()
        items = await ItemsContract.deployed()
        bounties = await BountiesContract.deployed()
        consumer = await ConsumerContract.deployed()
    })

    describe("User Functionality", async () => {
        it('User can self enroll', async () => {
            let { logs } = await users.enroll("admin 2", "twitterID-admin2", "URL-admin2", { from: admin2 })
            expectEvent.inLogs(logs, 'UserEnrolled', { _user: admin2 })
        })

        it('User cannot re-enroll self', async () => {
            await expectRevert(
                users.enroll("admin 2", "twitterID-admin2", "URL-admin2", { from: admin2 }),
                "User is enrolled"
            )
        })

        it('Admin can promote a user to admin', async () => {
            await expectRevert(
                users.promote(admin2, { from: admin2 }),
                "Caller is not an administrator"
            )
            let { logs } = await users.promote(admin2, { from: admin1 })
            expectEvent.inLogs(logs, 'UserPromoted', { _user: admin2 })
        })

        it('User can change their twitterID', async () => {
            let { logs } = await users.setTwitterId('changed-id', { from: admin2 })
            expectEvent.inLogs(logs, 'TwitterIDUpdated', { _user: admin2 })
        })

        it('Can view all data for a single user', async () => {
            let userId = await users.userID(admin2)
            let data = await users.users(userId)
            expect(data.name).to.be.equal('admin 2')
        })

        it('Can view summary data on all users', async () => {
            await users.enroll("member1", "twitterID-member1", "URL-member1", { from: member1 })
            await users.enroll("member2", "twitterID-member2", "URL-member2", { from: member2 })
            let data = await users.getUsers()
            let nonce = data._nonce.toNumber()
            // for (let i = 0; i < nonce; i++)
            //     console.log(`\nUser #${i}: ${data._names[i]} (Role: ${data._roles[i]})`)
            let member2URL = data._imageUrls[3]
            let member1Name = data._names[2]
            expect(member2URL).to.be.equal('URL-member2')
            expect(member1Name).to.be.equal('member1')
        })
    })

    describe("Announcement Functionality", async () => {
        it('onlyAdmin() for all announcement state mutations', async () => {
            await expectRevert(
                announcements.addAnnouncement('Title1', 'Body1', true, { from: member2 }),
                "Address not authenticated for this action"
            )
            await expectRevert(
                announcements.pinAnnouncement(1, { from: member2 }),
                "Address not authenticated for this action"
            )
        })

        it('Add announcement without pinning', async () => {
            let { logs } = await announcements.addAnnouncement(
                'Unpinned Title',
                'Unpinned Body',
                false,
                { from: admin1 }
            )
            expectEvent.inLogs(logs, 'AnnouncementAdded', { _nonce: new BN(1) })
            let pinned = await announcements.pinnedAnnouncement();
            expect(pinned.toNumber()).to.be.not.equal(1)
        })

        it('Add announcement and pin', async () => {
            let { logs } = await announcements.addAnnouncement(
                'Pinned Title',
                'Pinned Body',
                true,
                { from: admin1 }
            )
            expectEvent.inLogs(logs, 'AnnouncementAdded', { _nonce: new BN(2) })
            expectEvent.inLogs(logs, 'AnnouncementPinned', { _nonce: new BN(2) })
            let pinned = await announcements.pinnedAnnouncement();
            expect(pinned.toNumber()).to.be.equal(2)
        })

        it('Pin an existing announcement', async () => {
            let { logs } = await announcements.pinAnnouncement(1)
            expectEvent.inLogs(logs, 'AnnouncementPinned', { _nonce: new BN(1) })
        })
        it('Cannot pin already pinned announcement or no announcement', async () => {
            await expectRevert(
                announcements.pinAnnouncement(0),
                "Core: cannot set no pinned announcement!"
            )
            await expectRevert(
                announcements.pinAnnouncement(1),
                "Core: Announcement already pinned!"
            )
        })
        it('Return data for all announcements', async () => {
            await announcements.addAnnouncement('Title3', 'Body3', true, { from: admin1 })
            let data = await announcements.getAnnouncements()
            let nonce = await data._nonce.toNumber()
            // console.log("Pinned Announcement: ", data._pinned.toNumber())
            // for (let i = 0; i < nonce; i++)
            //     console.log(`Announcement #${i + 1} - Title: ${data._titles[i]}; Body: ${data._bodies[i]}`)
            expect(data._titles[1]).to.be.equal('Pinned Title')
            expect(data._bodies[2]).to.be.equal('Body3')
            expect(data._pinned.toNumber()).to.be.equal(nonce)
        })
    })

    describe("Item Functionality", async () => {
        before(async () => {
            await users.enroll("member3", "twitter", "image", { from: member3 })
            await bounties.addBounty("a", "b", "c", 1000, true, 0, true, "", { from: admin1 })
            await bounties.applyForBounty(1, { from: member1 })
            await bounties.applyForBounty(1, { from: member3 })
            await bounties.approveBountyRequest(1, 1, { from: admin1 })
            await bounties.approveBountyRequest(1, 1, { from: admin1 })
        })
        it('Admin can add a new infinite item', async () => {
            let { logs } = await items.addItem("Title", "Body", "URL", 10, true, 0, { from: admin1 })
            expectEvent.inLogs(logs, 'ItemAdded', { _nonce: new BN(1)})
            let data = await items.getItems()
            expect(data._titles[0]).to.be.equal("Title")
            expect(data._costs[0]).to.be.bignumber.equal(new BN(10))
            let { logs: logs2 } = await items.buyItem(1, { from: member1 })
            expectEvent.inLogs(
                logs2,
                'ItemPurchased',
                { _nonce: new BN(1), _by: member1, _burned: data._costs[0] }
            )
            data = await items.getItems()
            expect(data._infinites[0] && data._actives[0]).to.be.true
            await expectRevert(
                items.addItem("", "", "", 1, true, 0, { from: member1 }),
                "Address not authenticated for this action"
            )
            await expectRevert(
                items.buyItem(1, { from: member1 }),
                "User already owns item"
            )
        })
        it('Admin can add a new finite item', async () => {
            await items.addItem("Title2", "Body2", "URL2", 10, false, 1, { from: admin1 })
            await items.buyItem(2, { from: member1 })
            await expectRevert(
                items.buyItem(2, { from: member3 }),
                "Item not for sale"
            )
            let data = await items.getItems()
            expect(data._infinites[1] && data._actives[1]).to.be.false
        })
        it('Admin can delist an item', async () => {
            await expectRevert(
                items.delistItem(1, { from: member1 }),
                "Address not authenticated for this action"
            )
            let { logs } = await items.delistItem(1, { from: admin1 })
            expectEvent.inLogs(logs, 'ItemDelisted', { _nonce: new BN(1) })
            let data = await items.getItems()
            expect(data._infinites[0] && data._actives[0]).to.be.false
            await expectRevert(
                items.buyItem(1, { from: member3 }),
                "Item not for sale"
            )
            data = await items.getItems()
            expect(data._infinites[0] && data._actives[0]).to.be.false
        })
        it('Users without sufficient balance cannot buy items', async () => {
            await items.addItem("Title3", "Body3", "URL3", 10, false, 1, { from: admin1 })
            await expectRevert(
                items.buyItem(3, { from: member2 }),
                "User has insufficient balance"
            )
        })
    })

    describe("Bounty Functionality", async () => {
        it('Admin can add a new infinite manual bounty', async () => {
            let { logs } = await bounties.addBounty(
                'bounty1-title',
                'bounty1-description',
                'bounty1-url',
                100,
                true,
                0,
                true,
                "",
                { from: admin1 }
            )
            let bountyNonce = new BN(2)
            expectEvent.inLogs(logs, 'BountyAdded', { _nonce: bountyNonce })
            await bounties.applyForBounty(bountyNonce, { from: member1 })
            await bounties.approveBountyRequest(1, 1, { from: admin1 })
            let data = await bounties.getBounties()
            expect(data._titles[1]).to.be.equal('bounty1-title')
            expect(data._infinites[1] && data._actives[1] && data._manuals[1]).to.be.true
        })
        it('Admin can add a new finite bounty', async () => {
            let { logs } = await bounties.addBounty(
                'bounty2-title',
                'bounty2-description',
                'bounty2-url',
                100,
                false,
                1,
                true,
                "",
                { from: admin1 }
            )
            let bountyNonce = new BN(3)
            let data = await bounties.getBounties()
            expect(data._quantities[2].toNumber()).to.be.equal(1)
            expectEvent.inLogs(logs, 'BountyAdded', { _nonce: bountyNonce })
            await bounties.applyForBounty(bountyNonce, { from: member1 })
            await bounties.approveBountyRequest(1, 1, { from: admin1 });
            await expectRevert(
                bounties.applyForBounty(bountyNonce, { from: member2 }),
                "Bounty not in stock"
            )
            data = await bounties.getBounties()
            expect(data._titles[2]).to.be.equal('bounty2-title')
            expect(!data._infinites[2] && !data._actives[2] && data._manuals[2]).to.be.true
            expect(data._quantities[2].toNumber()).to.be.equal(0)
        })
        it('Only admin can list a bounty', async () => {
            await expectRevert(
                bounties.addBounty(
                    'revert-title',
                    'revert-description',
                    'revert-url',
                    100,
                    false,
                    1,
                    true,
                    "",
                    { from: member2 }
                ),
                "Address not authenticated for this action"
            )
        })
        it('Admin can delist a bounty', async () => {
            let { logs } = await bounties.addBounty(
                'bounty3-title',
                'bounty3-description',
                'bounty3-url',
                100,
                false,
                1,
                true,
                "",
                { from: admin1 }
            )
            let bountyNonce = new BN(4)
            let data = await bounties.getBounties()
            expect(data._actives[3]).to.be.true
            await bounties.delistBounty(bountyNonce, { from: admin1 })
            await expectRevert(
                bounties.applyForBounty(bountyNonce, { from: member1 }),
                "Bounty not available for application"
            )
            data = await bounties.getBounties()
            expect(data._actives[3]).to.be.false
        })

        it('Users can apply for bounties', async () => {
            let { logs } = await bounties.addBounty(
                'bounty4-title',
                'bounty4-description',
                'bounty4-url',
                100,
                false,
                5,
                true,
                "",
                { from: admin1 }
            )
            let bountyNonce = new BN(5)
            await bounties.applyForBounty(bountyNonce, { from: member1 })
            await bounties.applyForBounty(bountyNonce, { from: member2 })
            await expectRevert(
                bounties.applyForBounty(bountyNonce, { from: member1 }),
                "User has pending approval"
            )
            let data = await bounties.pendingBountyRequests(1)
            expect(data._nonce.toNumber()).to.be.equal(2)
            expect(data._users[0]).to.be.equal(member1)
            expect(data._bounties[1]).to.be.bignumber.equal(bountyNonce)
        })
        it('Admin can accept or manually accept or reject requests for approval', async () => {
            let bountyNonce = new BN(5)
            let oldBalance = (await users.balanceOf(member1)).toNumber()
            let { logs } = await bounties.approveBountyRequest(1, 1, { from: admin1 })
            expectEvent.inLogs(
                logs,
                'BountyAwarded',
                { _nonce: bountyNonce, _to: member1, _minted: new BN(100) }
            )
            await expectRevert(
                bounties.applyForBounty(bountyNonce, { from: member1 }),
                "User has has bounty"
            )
            let user = await users.getUser(member1)
            expect(user._balance.toNumber()).to.be.equal(oldBalance + 100)
            let userBounties = user._bounties.map(bounty => bounty.toNumber())
            expect(userBounties.includes(bountyNonce.toNumber())).to.be.true
            await bounties.rejectBountyRequest(1, 1, { from: admin1 })
        })
        it('Users rejected from bounty application are blacklisted from the bounty for 24 hours', async () => {
            let bountyNonce = new BN(5)
            await expectRevert(
                bounties.applyForBounty(bountyNonce, { from: member2 }),
                "Tempbanned < 24 hours ago"
            )
            // await time.increase(time.duration.days(1))
            // let { logs } = await bounties.applyForBounty(bountyNonce, { from: member2 })
            // expectEvent.inLogs(logs, "BountyApplication", { _nonce: bountyNonce, _by: member2 })
        })
        it('Users can autonomously award bounties with Twitter Chainlink approval', async () => {
        // This id will return false
        // This id will return true
        // await users.enroll("twitter2", "388447226", "URL-twitter2", { from: validTwitterMember2 })
        // await users.enroll("admin 1", "twitterID-admin1", "URL-admin1", { from: admin1 })
        await users.enroll("twitter1", "388447226", "URL-twitter1", { from: validTwitterMember1 })
        console.log('Adding Bounty...')
        await bounties.addBounty(
            'bounty1-title',
            'bounty1-description',
            'bounty1-url',
            100,
            true,
            0,
            false,
            "1321436762816872449",
            { from: admin1 }
        )
        let bountyNonce = new BN(1)
        console.log('Bounty Added. Applying for Bounty...')
        const { receipt } = await bounties.applyForBounty(bountyNonce, { from: validTwitterMember1 })
        let reqNonce = receipt.logs[0].args._requestNonce
        console.log('Bounty Applied For...')
        let fufilled = false
        while(!fufilled) {
            fufilled = await bounties.checkFulfillment(reqNonce)
            if(fufilled) {
                expect(await bounties.hasBounty(bountyNonce, validTwitterMember1)).to.be.true
            } else {
                console.log('Awaiting chainlink request fufillment')
                await sleep(20000)
            }
        }
        })
        it('If a user has not fufilled the bounty the chainlink adapter should return false', async () => {
        await users.enroll("twitter2", "123456", "URL-twitter2", { from: validTwitterMember2 })
            let bountyNonce = new BN(1)
            console.log('Applying for Bounty...')
            const { receipt } = await bounties.applyForBounty(bountyNonce, { from: validTwitterMember2 })
            let reqNonce = receipt.logs[0].args._requestNonce
            console.log('Bounty Applied For...')
            let fufilled = false
            while(!fufilled) {
                fufilled = await bounties.checkFulfillment(reqNonce)
                if(fufilled) {
                    expect(await bounties.hasBounty(bountyNonce, validTwitterMember2)).to.be.false
                } else {
                    console.log('Awaiting chainlink request fufillment')
                    await sleep(20000)
                }
            }
        })
    })
})