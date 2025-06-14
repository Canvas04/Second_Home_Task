// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Store is Ownable {
    /// @notice product_id => quantity
    mapping(uint256 => uint256) public productsPurchase;
    /// @notice addressof buyer => history of purchases
    mapping(address => PurchaseHistory[]) public userPurchases;

    /// @notice productName => quantity of purchases
    mapping(string => uint256) public purchaseNameQuantity;
    /// @notice product description
    struct Product {
        string name;
        uint256 id;
        uint256 stock;
        uint256 price;
    }

    /// @notice history of purchases
    struct PurchaseHistory {
        address buyer;
        string productName;
        uint256 purchaseId;
        uint256 totalAmount;
    }

    /// @notice Show quantity of purchases
    struct PurchaseQuantity {
        string productName;
        uint256 purchaseNumber;
    }

    Product[] private products;
    PurchaseHistory[] public purchases;
    uint256 internal purchaseId;

    event Purchase(address buyer, uint256 id, uint256 quantity);

    error IdAlreadyExist();
    error IdDoesNotExist();
    error OutOfStock();
    error NotEnoughtFunds();
    error QuantityCantBeZero();

    constructor() Ownable(msg.sender) {}

    function buy(uint256 _id, uint256 _quantity) external payable {
        require(_quantity > 0, QuantityCantBeZero());
        require(getStock(_id) >= _quantity, OutOfStock());

        uint256 totalPrice = getPrice(_id) * _quantity;
        require(msg.value >= totalPrice, NotEnoughtFunds());

        //buy
        _buyProcess(msg.sender, _id, _quantity);

        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
    }

    function batchBuy(uint256[] calldata _ids, uint256[] calldata _quantitys)
        external
        payable
    {
        require(_ids.length == _quantitys.length, "arrays lenghts mismatch");

        uint256 totalPrice = 0;

        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 q = _quantitys[i];
            uint256 id = _ids[i];

            require(q > 0, QuantityCantBeZero());
            require(getStock(id) >= q, OutOfStock());

            totalPrice += getPrice(id) * q;
        }

        require(msg.value >= totalPrice, NotEnoughtFunds());

        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 q = _quantitys[i];
            uint256 id = _ids[i];

            _buyProcess(msg.sender, id, q);
        }

        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
    }

    function _buyProcess(
        address buyer,
        uint256 _id,
        uint256 _quantity
    ) internal {
        Product storage product = findProduct(_id);
        product.stock -= _quantity;
     
        productsPurchase[_id] += _quantity;
        PurchaseHistory memory newPurchase = PurchaseHistory(
            buyer,
            product.name,
            purchaseId++,
            product.price * _quantity
        );
        purchases.push(newPurchase);
        userPurchases[buyer].push(newPurchase);
        purchaseNameQuantity[product.name] += _quantity;
        emit Purchase(buyer, _id, _quantity);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Not enought money");

        payable(owner()).transfer(balance);
    }

    function addProduct(
        string calldata _name,
        uint256 _id,
        uint256 _stock,
        uint256 _price
    ) external onlyOwner {
        require(!isIdExist(_id), IdAlreadyExist());
        products.push(Product(_name, _id, _stock, _price));
    }

    function deleteProduct(uint256 _id) external onlyOwner {
        (bool status, uint256 index) = findIndexById(_id);
        require(status, IdDoesNotExist());

        products[index] = products[products.length - 1];
        products.pop();
    }

    function updatePrice(uint256 _id, uint256 _price) external onlyOwner {
        Product storage product = findProduct(_id);
        product.price = _price;
    }

    function updateStock(uint256 _id, uint256 _stock) external onlyOwner {
        Product storage product = findProduct(_id);
        product.stock = _stock;
    }

    function getProducts() public view returns (Product[] memory) {
        return products;
    }

    function getPrice(uint256 _id) public view returns (uint256) {
        Product storage product = findProduct(_id);
        return product.price;
    }

    function getStock(uint256 _id) public view returns (uint256) {
        Product storage product = findProduct(_id);
        return product.stock;
    }

    function findProduct(uint256 _id)
        internal
        view
        returns (Product storage product)
    {
        for (uint256 i = 0; i < products.length; i++) {
            if (products[i].id == _id) {
                return products[i];
            }
        }
        revert IdDoesNotExist();
    }

    function isIdExist(uint256 _id) internal view returns (bool) {
        for (uint256 i = 0; i < products.length; i++) {
            if (products[i].id == _id) {
                return true;
            }
        }
        return false;
    }

    function findIndexById(uint256 _id) internal view returns (bool, uint256) {
        for (uint256 i = 0; i < products.length; i++) {
            if (products[i].id == _id) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    /// HomeTask

    /// @notice Refund money for last purchase
    /// @param _buyer Buyer address
    function refund(address _buyer) public payable {
        uint256 buyerPurchasesLength = userPurchases[_buyer].length;
        PurchaseHistory memory lastPurchase = userPurchases[_buyer][
            buyerPurchasesLength - 1
        ];

        uint256 balance = address(this).balance + lastPurchase.totalAmount;

        require(balance > 0, "Not enought money");
        payable(owner()).transfer(lastPurchase.totalAmount);
    }

    /// @notice Get purchases history
    /// @param _buyer Buyer address
    /// @return purchases history
    function getUserPurchase(address _buyer, uint256 _purchaseId)
        public
        view
        returns (PurchaseHistory memory)
    {
        PurchaseHistory memory purchase;
        PurchaseHistory[] storage buyerPurchases = userPurchases[_buyer];
        for (uint256 i = 0; i < buyerPurchases.length; i++) {
            if (_purchaseId == buyerPurchases[i].purchaseId) {
                purchase = userPurchases[_buyer][i];
            }
        }
        return purchase;
    }

    /// @notice Get total sum, which shop get
    function getTotalRevenue() public view returns (uint256) {
        uint256 totalRevenue;

        for (uint256 i = 0; i < purchases.length; i++) {
            totalRevenue += purchases[i].totalAmount;
        }
        return totalRevenue;
    }

    /// @notice Get a most popular selling product
    function getTopSellingProducts()
        public
        view
        returns (PurchaseQuantity memory mostPurchasesProduct)
    {
        uint256 maxAmountPurchases;
        string memory mostSellingProduct;
        for (uint256 i = 0; i < purchases.length; i++) {
            string memory productName = purchases[i].productName;
            uint256 productQuantity = purchaseNameQuantity[productName];
            if (
                productQuantity
                > maxAmountPurchases
            ) {
                maxAmountPurchases = productQuantity;
                mostSellingProduct = productName;
            }
        }
        return PurchaseQuantity(mostSellingProduct, maxAmountPurchases);
    }
}
