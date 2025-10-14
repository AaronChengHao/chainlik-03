// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";


// 1. 创建收款函数
// 2. 记录投资人并查看
// 3. 在锁定期内，达到目标值，生产商可以提款
// 4. 在锁定期内，未达到目标值，投资人在锁定期后可以提款

contract FundMe{
    mapping(address => uint256) public fundersToAmount;

    // uint256 MINIMUM_VALUE = 1 ether; // 1*10**18;
    uint256 MINIMUM_VALUE = (10 ** 18) * 100; // USD

    AggregatorV3Interface internal dataFeed;

    // constant 声明常量
    uint256 constant TARGET = 1000 * 10 ** 18; // 1000 USD

    address public  owner;

    constructor() {
        // 给合约对象赋值 - sepolia-testnet
        dataFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        owner = msg.sender;
    }

    function fund() external  payable  {
        require( convertEthToUsd(msg.value) >= MINIMUM_VALUE, "send more eht"); // 必须要为true，如果不为true，则交易失败，回退
        fundersToAmount[msg.sender] += msg.value;
    }

   /**
     * Returns the latest answer.
     */
    function getChainlinkDataFeedLatestAnswer() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundId */,
            int256 answer,
            /*uint256 startedAt*/,
            /*uint256 updatedAt*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return answer;
    }

    function convertEthToUsd(uint256 ethAmount) public  view returns (uint256) {
        uint256 ethPrice = uint256(getChainlinkDataFeedLatestAnswer());
        return  ethAmount * ethPrice / (10 **8);
        // EHT/USD percision = 10 ** 8;
        // X/ETH percision = 10 ** 18;
        // ETH/EUSD = 1/4191
        // ETH/EUSD = 1000000000000000000/419136016500
    }

    function transferOwnership(address newOwner) public  {
        require(msg.sender == owner, "this function is owner call");
        owner = newOwner;
    }

    function getFund() public payable   {
        require( convertEthToUsd(address(this).balance) /* wei */  >= TARGET,  "Target is not reached");
        require(msg.sender == owner, "");
        // 转转方式
        // transfer: transfer ETH and revert if tx failed
        // payable(msg.sender).transfer(address(this).balance);

        // send: transfer ETH and return false if failed
        // bool  success = payable(msg.sender).send(address(this).balance);
        // require(success, "");

        // call: transfer ETH with data return value of function and bool
        bool  success;
        (success, ) =  payable(msg.sender).call{value:address(this).balance}("");

        fundersToAmount[msg.sender] = 0;
    }
    

    function refund() public   {
        require( convertEthToUsd(address(this).balance) /* wei */  < TARGET,  "Target is reached");

        uint256 amount = fundersToAmount[msg.sender];

        require(amount > 0, "there is no fund for you");

        bool  success;
        (success,) =  payable(msg.sender).call{value:amount}("");
        require(success, "transfer tx faild");

        fundersToAmount[msg.sender] = 0;
    }

    function getDataFeedPrice () public view  returns(uint256) {
        return uint256(getChainlinkDataFeedLatestAnswer());

    }

    function testView() public pure returns (string memory) {
        return "hello world";
    }
}