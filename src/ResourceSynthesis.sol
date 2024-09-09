// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ResourceSynthesis is Ownable {
    IERC20 public starToken;

    struct Resource {
        uint256 id;
        uint256 level;
        string name;
    }

    mapping(uint256 => Resource) public resources; 
    mapping(address => mapping(uint256 => uint256)) public userResources; // User's resources by resource ID

    uint256 public synthesisCost;

    mapping(uint256 => mapping(uint256 => uint256)) public synthesisPaths; // Maps two lower-level resources to one higher-level resource

    constructor(IERC20 _starToken, uint256 _synthesisCost) {
        starToken = _starToken;
        synthesisCost = _synthesisCost;
    }

    function setSynthesisCost(uint256 _cost) external onlyOwner {
        synthesisCost = _cost;
    }

    function addResource(uint256 id, uint256 level, string memory name) external onlyOwner {
        resources[id] = Resource(id, level, name);
    }

    function setSynthesisPath(uint256 resourceIdLow1, uint256 resourceIdLow2, uint256 resourceIdHigh) external onlyOwner {
        synthesisPaths[resourceIdLow1][resourceIdLow2] = resourceIdHigh;
    }

    function synthesize(
        uint256 resourceIdLow1,
        uint256 resourceIdLow2,
        uint256 amountLow
    ) external {
        require(resources[resourceIdLow1].level != 0 && resources[resourceIdLow2].level != 0, "Invalid resources");
        require(resources[resourceIdLow1].level == resources[resourceIdLow2].level, "Resources must be same level");

        uint256 resourceIdHigh = synthesisPaths[resourceIdLow1][resourceIdLow2];
        require(resourceIdHigh != 0, "Invalid synthesis path");
        require(resources[resourceIdHigh].level == resources[resourceIdLow1].level + 1, "Invalid target resource level");
        require(userResources[msg.sender][resourceIdLow1] >= amountLow, "Insufficient low resource 1");
        require(userResources[msg.sender][resourceIdLow2] >= amountLow, "Insufficient low resource 2");
        require(starToken.transferFrom(msg.sender, address(this), synthesisCost), "STAR token transfer failed");

        userResources[msg.sender][resourceIdLow1] -= amountLow;
        userResources[msg.sender][resourceIdLow2] -= amountLow;
        userResources[msg.sender][resourceIdHigh] += amountLow / 2;
    }

    function withdrawStar(uint256 amount) external onlyOwner {
        starToken.transfer(msg.sender, amount);
    }

    function addUserResource(address user, uint256 resourceId, uint256 amount) external onlyOwner {
        userResources[user][resourceId] += amount;
    }
}
