// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Store is Ownable {
    /// @notice buyer => product_id => quantity
    mapping(address => PurchaseHistory[]) public userPurchase;
    /// @notice product_id => quantity
    mapping(uint256 => uint256) public productsPurchase;

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
        uint256 purchaseId;
        uint256 totalAmount;
    }

    PurchaseHistory[] public purchasesForCurrentBuyer;

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

        setPurchaseHistory(buyer, product.price * _quantity);
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

    ///@notice Set history of purchases of current buyer
    /// @param buyer Buyer
    /// @param _totalAmout Sum, which buyer spend for purchase
    function setPurchaseHistory(address buyer, uint256 _totalAmout) internal {
        purchaseId++;
        purchases.push(PurchaseHistory(buyer, purchaseId, _totalAmout));
    }

    /// Возможно надо еще обновить количество товара после возврата денег
    /// @notice Refund money for last purchase for buyer
    /// @param _buyer Buyer
    function refund(address _buyer) public payable {
        PurchaseHistory memory lastPurchase = getLastPurchase(_buyer);
        uint256 balance = address(this).balance + lastPurchase.totalAmount;

        require(balance > 0, "Not enought money");

        payable(owner()).transfer(lastPurchase.totalAmount);
    }

    /// @notice Get last purchase of buyer
    /// address buyer Buyer
    /// @return Purchase with max purchaseId among purchases of buyer
    function getLastPurchase(address _buyer)
        internal
        view
        returns (PurchaseHistory memory)
    {
        PurchaseHistory[] memory currentBuyer = userPurchase[_buyer];
        return currentBuyer[currentBuyer.length - 1];
    }

    /// @notice get amount of money, which a shop get
    function getTotalRevenue() public view returns (uint256) {
        uint256 totalRevenue;

        for (uint256 i = 0; i < purchases.length; i++) {
            totalRevenue += purchases[i].totalAmount;
        }
        return totalRevenue;
    }

    // Нужно чтобы эта функция возвращала значения
    /// @notice get history of purchases for current buyer
    function getUserPurchase(address _buyer)
        public
    {
        for (uint256 i = 0; i < purchases.length; i++) {
            if (purchases[i].buyer == _buyer) {
                purchasesForCurrentBuyer.push(purchases[i]);
            }
        }
        userPurchase[_buyer] = purchasesForCurrentBuyer;
    }
}
