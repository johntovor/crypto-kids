// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract CryptoKids {
    // owner DAD
    address private immutable i_owner;

    constructor() {
        i_owner = msg.sender;
    }

    // define kid
    struct Kid {
        address walletAddress;
        string firstName;
        string lastName;
        uint256 amount;
        uint256 releaseTime;
        bool canWithdraw;
    }

    Kid[] public kids;

    function getIndex(address walletAddress) private view returns (uint256 i) {
        for (i = 0; i < kids.length; i++) {
            if (kids[i].walletAddress == walletAddress) {
                return i;
            }
        }
    }

    modifier onlyOwner() {
        require(i_owner == msg.sender);
        _;
    }

    modifier untilReleaseTime(address walletAddress) {
        uint256 i = getIndex(walletAddress);
        require(block.timestamp > kids[i].releaseTime);
        _;
    }

    // add kid to contract
    function addKid(
        address _walletAddress,
        string memory _firstName,
        string memory _lastName,
        uint256 _amount,
        uint256 _releaseTime,
        bool _canWithdraw
    ) public onlyOwner {
        Kid memory kid = Kid({
            walletAddress: _walletAddress,
            firstName: _firstName,
            lastName: _lastName,
            amount: _amount,
            releaseTime: _releaseTime,
            canWithdraw: _canWithdraw
        });
        kids.push(kid);
    }

    // get kid's balance
    function balanceOf() public view returns (uint256) {
        return address(this).balance;
    }

    // deposit into kid's account
    function deposit(address walletAddress) public payable onlyOwner {
        addToKidsBalance(walletAddress);
    }

    function addToKidsBalance(address walletAddress) private {
        uint256 i = getIndex(walletAddress);
        if (kids[i].walletAddress == walletAddress) {
            kids[i].amount += msg.value;
        }
    }

    // kid checks if can withdraw
    function kidCanWithdraw(
        address walletAddress
    ) public untilReleaseTime(walletAddress) returns (bool) {
        uint256 i = getIndex(walletAddress);
        if (kids[i].walletAddress == msg.sender) {
            kids[i].canWithdraw = true;
            return true;
        } else {
            return false;
        }
    }

    // withdraw money
    function withdraw(
        address walletAddress
    ) public payable untilReleaseTime(walletAddress) {
        uint256 i = getIndex(walletAddress);
        require(
            kids[i].walletAddress == msg.sender,
            "You are not the account owner"
        );
        (bool success, ) = payable(kids[i].walletAddress).call{
            value: kids[i].amount
        }("");
        require(success, "Call failed");
    }
}
