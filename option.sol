// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "hardhat/console.sol";

contract Option{
    address public seller;
    address public buyer;
    address public underlying = 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43; //BTC
    uint256 public strike; //in wei
    uint256 public price; //in wei
    uint256 public duration; //seconds
    uint256 public buy_time; //seconds
    uint256 public max_amount; //in 0.001 units
    uint256 amount; //in 0.001 units
    bool public available;
    bool public exercised;

    AggregatorV3Interface internal priceFeed;
    AggregatorV3Interface internal priceFeedETH;

    constructor(uint256 max, uint256 p, uint256 s, uint256 d) payable {
        priceFeed = AggregatorV3Interface(underlying); // BTC/USD
        priceFeedETH = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306); // ETH//USD
        (, int price_under,,,) = priceFeed.latestRoundData();
        (, int price_ETH,,,) = priceFeedETH.latestRoundData();
        uint256 price_under_ETH = uint256(price_under) * 1e18 / uint256(price_ETH);
        require(msg.value >= max*price_under_ETH/1000/10, "Not enough collateral");
        seller = msg.sender;
        strike = s;
        price = p;
        duration = d;
        max_amount = max;
        available = true;
        exercised = false;
    }

    function adjustPrice(uint256 p) public {
        require(msg.sender == seller, "Only seller can change the price");
        require(available == true, "Price can only be changed before sale");
        price = p;
    }

    function getLatestPrice() public view returns (uint256, int) {
        (, int price_under,,,) = priceFeed.latestRoundData();
        (, int price_ETH,,,) = priceFeedETH.latestRoundData();
        return (uint256(price_under) * 1e18 / uint256(price_ETH), price_under); //price of underlying in wei and USD
    }

    function getRemTime() public view returns (uint256) {
        return buy_time + duration - block.timestamp;
    }

    function getValue() public view returns (uint256) {
        (, int price_under,,,) = priceFeed.latestRoundData();
        (, int price_ETH,,,) = priceFeedETH.latestRoundData();
        uint256 price_under_ETH = uint256(price_under) * 1e18 / uint256(price_ETH); //price of underlying in wei
        uint256 value;
        if(price_under_ETH > strike){
            value = (price_under_ETH-strike) * amount / 1000;
        }
        else {
            value = 0;
        }
        return value;
    }

    function buy(uint256 a) public payable {
        require(msg.value == a*price/1000, "Wrong payment");
        require(a<=max_amount, "Too many contracts");
        require(available == true, "No longer available");
        buyer = msg.sender;
        available = false;   
        buy_time = block.timestamp;
    }

    function exercise() public payable {
        require(exercised == false, "Already exercised");
        require(available == false, "Option not bought yet");
        if (block.timestamp < buy_time + duration){
            require(msg.sender == buyer, "Only buyer can exercise before expiration");
        }
        (, int price_under,,,) = priceFeed.latestRoundData();
        (, int price_ETH,,,) = priceFeedETH.latestRoundData();
        uint256 price_under_ETH = uint256(price_under) * 1e18 / uint256(price_ETH); //price of underlying in wei
        uint256 value;
        if(price_under_ETH > strike){
            value = (price_under_ETH-strike) * amount / 1000;
        }
        else {
            value = 0;
        }
        payable(buyer).transfer(value >= address(this).balance ? address(this).balance : value);
        payable(seller).transfer(address(this).balance);
        exercised = true;
    }
} 
