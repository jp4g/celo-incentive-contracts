//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IUsers.sol";

abstract contract IItems {
    /// LIBRARIES ///

    using SafeMath for uint256;

    /// EVENTS ///

    event ItemAdded(uint256 _nonce);
    event ItemPurchased(uint256 _nonce, address _by, uint256 _burned);
    event ItemDelisted(uint256 _nonce);

    /// MODIFIERS ///

    modifier beforeItemBuy(uint256 _item) {
        require(items[_item].active, "Item not for sale");
        require(
            items[_item].infinite || items[_item].quantity > 0,
            "Item not in stock"
        );
        require(
            userContract.balanceOf(msg.sender) >= items[_item].cost,
            "User has insufficient balance"
        );
        require(!items[_item].purchased[msg.sender], "User already owns item");
        _;
    }

    modifier onlyAdmin() {
        require(
            userContract.role(msg.sender) == 2,
            "Address not authenticated for this action"
        );
        _;
    }

    /// VARIABLES ///

    IUsers userContract;
    uint256 public itemNonce;
    mapping(uint256 => Item) public items;

    /// MUTABLE FUNCTIONS ///

    /**
     * List a new item for purchase
     * @dev modifier onlyAdmin
     *
     * @param _title - the title text for the item
     * @param _description - the body text for the item
     * @param _imageUrl - the s3 bucket url for the item's image
     * @param _cost - the number of orgtokens to charge for this item
     * @param _infinite - true if the item should be infinitely purchasable, false otherwise
     * @param _quantity - number of times the item can be sold (if _infinite == false)
     * @return _nonce - the index of the item on-chain
     */
    function addItem(
        string memory _title,
        string memory _description,
        string memory _imageUrl,
        uint256 _cost,
        bool _infinite,
        uint256 _quantity
    ) public virtual returns (uint256 _nonce);

    /**
     * Purchase an item
     * @dev modifier onlyUser, sufficientBalance
     *
     * @param _nonce - the index of the item being purchased
     * @return _balance - the orgtoken balance of the caller after the purchase
     */
    function buyItem(uint256 _nonce) public virtual returns (uint256 _balance);

    /**
     * Delist an item for purchase
     * @dev modifier onlyAdmin
     *
     * @param _nonce - the index of the item to delist
     */
    function delistItem(uint256 _nonce) public virtual;

    /// VIEWABLE FUNCTIONS ///

    /**
     * Get critical data on every item on-chain
     *
     * @return _itemNonce - the number of items returned/ on the contract
     * @return _titles - array of items' title text
     * @return _descriptions - array of items' description text
     * @return _imageUrls - array of items' s3 image urls
     * @return _costs - array of items' OrgToken cost of purchase
     * @return _infinites - array of infinite-in-stock true or false field
     * @return _quantities - array of items' stock quanitities (if not infinite)
     * @return _actives - array of items' active listing state in true or false
     */
    function getItems()
        public
        virtual
        view
        returns (
            uint256 _itemNonce,
            string[] memory _titles,
            string[] memory _descriptions,
            string[] memory _imageUrls,
            uint256[] memory _costs,
            bool[] memory _infinites,
            uint256[] memory _quantities,
            bool[] memory _actives
        );
}

struct Item {
    string title;
    string description;
    string imageUrl;
    uint256 cost;
    bool infinite;
    uint256 quantity;
    bool active;
    mapping(address => bool) purchased;
    address[] owners;
}
