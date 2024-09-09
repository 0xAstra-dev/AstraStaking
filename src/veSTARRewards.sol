// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IBeraPool {
    function addLiquidity(uint256 amount) external returns (uint256);
    function getLPToken() external view returns (address);
}

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract AstraPoolRewards is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public astraToken;  // ASTR token
    IERC20 public iBGTToken;   // iBGT token for rewards
    IBeraPool public beraPool; // Berachain pool for liquidity provision

    uint256 public gamePoolBalance;  
    uint256 public stakingPoolBalance; 

    event LiquidityAdded(address indexed user, uint256 amount, uint256 lpTokens);
    event Staked(address indexed user, uint256 amount);
    event ClaimedRewards(address indexed user, uint256 rewardAmount);

    constructor(
        address _astraToken,
        address _iBGTToken,
        address _beraPool
    ) {
        astraToken = IERC20(_astraToken);
        iBGTToken = IERC20(_iBGTToken);
        beraPool = IBeraPool(_beraPool);
    }

    // Cross-chain fees are used to add liquidity and generate LP tokens
    function addLiquidity(uint256 amount) external onlyOwner {
        astraToken.transferFrom(msg.sender, address(this), amount);

        // Add liquidity to the Berachain pool
        uint256 lpTokens = beraPool.addLiquidity(amount);
        emit LiquidityAdded(msg.sender, amount, lpTokens);

        distributeRewards();
    }

    function distributeRewards() internal {
        uint256 iBGTBalance = iBGTToken.balanceOf(address(this));
        require(iBGTBalance > 0, "No iBGT rewards to distribute");

        uint256 stakingShare = (iBGTBalance * 70) / 100; 
        uint256 gamePoolShare = iBGTBalance - stakingShare;

        stakingPoolBalance += stakingShare;
        gamePoolBalance += gamePoolShare;
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake 0");
        astraToken.transferFrom(msg.sender, address(this), amount);
        
        stakingPoolBalance += amount;
        emit Staked(msg.sender, amount);
    }

    function claimRewards() external {
        uint256 rewardAmount = calculateRewards(msg.sender);
        require(rewardAmount > 0, "No rewards to claim");

        iBGTToken.transfer(msg.sender, rewardAmount);
        emit ClaimedRewards(msg.sender, rewardAmount);
    }

    function calculateRewards(address user) public view returns (uint256) {
        uint256 userStake = astraToken.balanceOf(user);
        return (stakingPoolBalance * userStake) / totalStaked();
    }

    function totalStaked() public view returns (uint256) {
        return astraToken.balanceOf(address(this));
    }

    function withdrawFromGamePool(uint256 amount) external onlyOwner {
        require(gamePoolBalance >= amount, "Insufficient game pool balance");
        gamePoolBalance -= amount;
        astraToken.transfer(msg.sender, amount);
    }
}
