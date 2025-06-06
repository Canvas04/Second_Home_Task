// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Election {
    string[] public electors;

    uint256 public maxVotes;
    uint256 public allVotes;
    uint256 public electionEndTimeInMinutes;
    address public owner;
    bool public isElectionActive;

    mapping(address => bool) public userVotes;

    mapping(uint256 => uint256) public numberOfVotes;

    constructor(string[] memory _electors, uint256 _maxVotes,uint256 _electionEndTimeInMinutes) {
        electors = _electors;
        maxVotes = _maxVotes;
        owner = msg.sender;
        isElectionActive = true;
        electionEndTimeInMinutes = _electionEndTimeInMinutes * 60 + block.timestamp;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Not the contract owner");
        _;
    }

    function vote(uint256 _number) public {
        require(userVotes[msg.sender] == false, "Your address can't vote");
        require(_number < electors.length, "Elector does not exist");
        require(maxVotes > allVotes, "Maximum number of votes exceeded");
        require(owner != msg.sender, "Owner doesn`t vote");
        require(isElectionActive == true, 'Elections are closed');
        require(block.timestamp < electionEndTimeInMinutes, 'Time of elections is ended');
        userVotes[msg.sender] = true;
        numberOfVotes[_number] += 1;
        allVotes += 1;
    }

    function stopVote() public onlyOwner {
        isElectionActive = false;
    }
}
