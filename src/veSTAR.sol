// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract veSTAR {
    IERC20 public starToken;

    uint256 public constant MAX_LOCK_TIME = 4 * 365 * 86400;

    struct LockInfo {
        uint256 amount;
        uint256 unlockTime; 
    }

    mapping(address => LockInfo) public locked; 

    event Locked(address indexed user, uint256 amount, uint256 unlockTime);
    event Withdrawn(address indexed user, uint256 amount);

    constructor(address _starToken) {
        starToken = IERC20(_starToken);
    }

    function lock(uint256 amount, uint256 time) external {
        require(time > 0 && time <= MAX_LOCK_TIME, "Invalid lock time");
        require(amount > 0, "Cannot lock 0 tokens");

        starToken.transferFrom(msg.sender, address(this), amount);

        uint256 unlockTime = block.timestamp + time;

        locked[msg.sender].amount += amount;
        locked[msg.sender].unlockTime = unlockTime;

        emit Locked(msg.sender, amount, unlockTime);
    }

    function calculateveSTAR(address user) public view returns (uint256) {
        LockInfo memory lockData = locked[user];
        if (block.timestamp >= lockData.unlockTime) {
            return 0; 
        }
        uint256 lockDuration = lockData.unlockTime - block.timestamp;
        return (lockData.amount * lockDuration) / MAX_LOCK_TIME;
    }

    function withdraw() external {
        LockInfo memory lockData = locked[msg.sender];
        require(block.timestamp >= lockData.unlockTime, "Lock period has not expired");
        require(lockData.amount > 0, "No tokens to withdraw");

        uint256 amount = lockData.amount;
        locked[msg.sender].amount = 0;  

        starToken.transfer(msg.sender, amount); 
        emit Withdrawn(msg.sender, amount);
    }

    function getVotingPower(address user) external view returns (uint256) {
        return calculateveSTAR(user); 
    }
}
