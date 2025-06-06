// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Marketplace is Ownable {
    struct Product {
        string name;
        uint256 price;
        string status;
    }

    struct User {
        string name;
        string email;
        bool isRegistered;
    }

    Product[] public products;
    mapping(address => User) public users;

    event UserRegistered(address indexed user, string name, string email);

    constructor() Ownable(msg.sender) {}

    function createProduct(Product memory item) public onlyOwner {
        products.push(item);
    }

    function getProducts() external view returns (Product[] memory) {
        return products;
    }

    function registerUser(string memory _name, string memory _email) external {
        require(!users[msg.sender].isRegistered, "Already registered");
        users[msg.sender] = User(_name, _email, true);
        emit UserRegistered(msg.sender, _name, _email);
    }

    function getUserInfo(address _user) public view returns (User memory) {
        return users[_user];
    }

    function transferEther(uint256 _productId) public payable returns (bool isSuccessful, bytes memory data) {
        // (bool success,bytes memory data ) = _recipient.call{value: msg.value}("");
        (bool success, ) = owner().call{value: product.price}("");
        
    }
}
