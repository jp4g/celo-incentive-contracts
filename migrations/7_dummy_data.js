const UsersContract = artifacts.require("Users")
const AnnouncementsContract = artifacts.require("Announcements")
const ItemsContract = artifacts.require("Items")
const BountiesContract = artifacts.require("Bounties")

module.exports = async (deployer, network, accounts) => {
    if (true) {

        // get deployed contracts
        const users = await UsersContract.deployed()
        const announcements = await AnnouncementsContract.deployed()
        const items = await ItemsContract.deployed()
        const bounties = await BountiesContract.deployed()

        // deploy users
        let admin1 = accounts[0]
        let user1 = accounts[3]
        let user2 = accounts[4]
        let user3 = accounts[5]
        let image = 'AOh14GgHdiwS3EV4d5EXfbXC4mNcEONbthxkBNQllmjz' //not doing different photos

        let ian = {
            address: '0xeaB338Ee4D7Bc440DC9612f33c4Ed1C35ff0dd5a',
            name: 'Ian Brighton',
            twitter: '1214717683490578434',
            image: 'AOh14Gjarz3Uhu7td6R2jhSr2bJwPrwG-uHJSjUuMxud',
        }

        await users.enrollAdmin(ian.address, ian.name, ian.twitter, ian.image, { from: admin1 })

        await announcements.addAnnouncement(
            'Announcement 1',
            'This is my first announcement!',
            false,
            { from: admin1 }
        )

        await announcements.addAnnouncement(
            'Announcement 2',
            'This is my second announcement!',
            false,
            { from: admin1 }
        )
        await announcements.addAnnouncement(
            'Announcement 3',
            'This is my BEST ANNOUNCEMENT EVER!',
            true,
            { from: admin1 }
        )

        await users.enroll("User 1", "", image, { from: user1 })
        await users.enroll("User 2", "", image, { from: user2 })
        await users.enroll("User 3", "", image, { from: user3 })

        // deploy items
        await items.addItem("Item 1", "This is the body for Item 1!", "", 10, true, 0, { from: admin1 })
        await items.addItem("Item 2", "This is the body for Item 2!", "", 20, false, 3, { from: admin1 })

        // deploy bounties
        await bounties.addBounty(
            'Bounty 1',
            'This is the description for the first manual bounty.',
            "",
            100,
            true,
            0,
            true,
            "",
            { from: admin1 }
        )
        await bounties.addBounty(
            'Bounty 2',
            'This is the description for the second manual bounty.',
            "",
            100,
            false,
            3,
            true,
            "",
            { from: admin1 }
        )
    }

}