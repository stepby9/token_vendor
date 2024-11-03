// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {
    uint256 public constant tokensPerEth = 100;
    YourToken public yourToken;

    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event SellTokens(address seller, uint256 amountOfTokens, uint256 amountOfETH);

    constructor(address tokenAddress) {
        yourToken = YourToken(tokenAddress);
    }

    function buyTokens() external payable {
        require(msg.value > 0, "Must send ETH to buy tokens");

        uint256 amountOfTokens = msg.value * tokensPerEth;
        require(yourToken.balanceOf(address(this)) >= amountOfTokens, "Vendor contract does not have enough tokens");

        yourToken.transfer(msg.sender, amountOfTokens);
        emit BuyTokens(msg.sender, msg.value, amountOfTokens);
    }

    function sellTokens(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");

        // Calculate the amount of ETH to send back to the seller
        uint256 amountOfETH = amount / tokensPerEth;
        require(address(this).balance >= amountOfETH, "Vendor contract does not have enough ETH");

        // Transfer tokens from the seller to the vendor
        bool success = yourToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");

        // Send ETH to the seller
        (success, ) = msg.sender.call{value: amountOfETH}("");
        require(success, "ETH transfer failed");

        emit SellTokens(msg.sender, amount, amountOfETH);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");

        payable(owner()).transfer(balance);
    }
}
