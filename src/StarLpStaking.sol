// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IBeraChef {
    function queueNewCuttingBoard(address valCoinbase, uint64 startBlock, Weight[] calldata weights) external;
}

interface IBerachainRewardsVault {
    function stake(uint256 amount) external;
    function claimRewards() external;
}

interface IBerachainRewardsVaultFactory {
    function createRewardsVault(address stakingToken) external returns (address);
    function getVault(address stakingToken) external view returns (address);
}

interface IveSTAR {
    function calculateveSTAR(address user) external view returns (uint256);
}

contract StarLPStaking {
    IERC20 public lpToken;       
    IERC20 public bgtToken;      
    IBeraChef public beraChef;    
    IBerachainRewardsVault public rewardVault;  // Vault to handle reward distribution
    IBerachainRewardsVaultFactory public vaultFactory;
    IveSTAR public veSTARContract;  // veSTAR contract for reward boost

    mapping(address => uint256) public stakedAmounts;
    mapping(address => uint256) public rewardDebt;

    uint256 public totalStaked;
    uint256 public rewardsPerTokenStored;
    uint256 public lastUpdateBlock;
    uint256 public rewardRate; 

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 rewardAmount);
    event VaultCreated(address stakingToken, address rewardVault);

    constructor(
        address _lpToken,
        address _bgtToken,
        address _vaultFactory,
        address _beraChef,
        address _veSTARContract,
        uint256 _rewardRate
    ) {
        lpToken = IERC20(_lpToken);
        bgtToken = IERC20(_bgtToken);
        vaultFactory = IBerachainRewardsVaultFactory(_vaultFactory);
        beraChef = IBeraChef(_beraChef);
        veSTARContract = IveSTAR(_veSTARContract);
        rewardRate = _rewardRate;

        // Create a reward vault for the STAR LP token
        address vaultAddress = vaultFactory.createRewardsVault(_lpToken);
        rewardVault = IBerachainRewardsVault(vaultAddress);

        emit VaultCreated(_lpToken, vaultAddress);
    }

    modifier updateReward(address user) {
        rewardsPerTokenStored = rewardPerToken();
        lastUpdateBlock = block.number;
        if (user != address(0)) {
            rewardDebt[user] = earned(user);
        }
        _;
    }

    function stake(uint256 amount) external updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0 tokens");
        stakedAmounts[msg.sender] += amount;
        totalStaked += amount;
        lpToken.transferFrom(msg.sender, address(this), amount);

        rewardVault.stake(amount);

        emit Staked(msg.sender, amount);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardsPerTokenStored;
        }
        return rewardsPerTokenStored + ((rewardRate * (block.number - lastUpdateBlock) * 1e18) / totalStaked);
    }

    function calculateBaseReward(address user) public view returns (uint256) {
        return (stakedAmounts[user] * rewardPerToken()) / 1e18 - rewardDebt[user];
    }

    // Calculate boosted rewards based on veSTAR
    function getBoostedRewards(address user) public view returns (uint256) {
        uint256 baseReward = calculateBaseReward(user); 
        uint256 veStarBalance = veSTARContract.calculateveSTAR(user);  

        uint256 boostedReward = baseReward + (baseReward * veStarBalance / 1e18); 
        return boostedReward;
    }


    function claimRewards() external updateReward(msg.sender) {
        uint256 boostedReward = getBoostedRewards(msg.sender);  
        require(boostedReward > 0, "No rewards to claim");

        rewardVault.claimRewards();  
        bgtToken.transfer(msg.sender, boostedReward);

        emit RewardsClaimed(msg.sender, boostedReward);
    }

    function withdraw(uint256 amount) external updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        require(stakedAmounts[msg.sender] >= amount, "Insufficient balance");

        stakedAmounts[msg.sender] -= amount;
        totalStaked -= amount;
        lpToken.transfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }
}
