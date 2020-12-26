require("dotenv").config
const AnnouncementContract = artifacts.require("./Announcements")

module.exports = async (deployer) => {
    await deployer.deploy(AnnouncementContract)
}