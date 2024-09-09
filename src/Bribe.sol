// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBGT {
    function queueBoost(address validator, uint128 amount) external;
    function activateBoost(address validator) external;
    function boosts(address account) external view returns (uint128);
    function boostees(address validator) external view returns (uint128);
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract DelegatorBribe {
    IERC20 public iBGTToken;  // iBGT reward token
    IERC20 public starToken;  // STAR reward token
    IBGT public bgtContract;  // BGT contract for boost functionality
    address public validator; 

    uint256 public epochDuration;    // Duration of each epoch in seconds
    uint256 public lastEpochTime;    // Timestamp of the last epoch
    uint256 public totalIBGTBribe;  
    uint256 public totalSTARBribe;   
    uint128 public validatorTotalBoost; 

    uint256 public minStakeDuration = 1 days; 
    uint256 public lockDuration = 1 days;     

    mapping(address => uint256) public delegationTimestamp; // Timestamp when a delegator staked
    mapping(address => uint128) public delegationAmount;    
    mapping(address => uint256) public claimedIBGT;        
    mapping(address => uint256) public claimedSTAR;         
    mapping(address => uint256) public lastClaimedEpoch;    

    event BribeDeposited(uint256 iBGTAmount, uint256 starAmount);
    event BribeClaimed(address indexed delegator, uint256 iBGTAmount, uint256 starAmount);

    constructor(
        IERC20 _iBGTToken,
        IERC20 _starToken,
        IBGT _bgtContract,
        address _validator,
        uint256 _epochDuration
    ) {
        iBGTToken = _iBGTToken;
        starToken = _starToken;
        bgtContract = _bgtContract;
        validator = _validator;
        epochDuration = _epochDuration;
        lastEpochTime = block.timestamp;
    }

    function queueBoost(address validator, uint128 newAmount) external {
        uint128 currentBoost = bgtContract.boosts(msg.sender); 
        uint128 updatedAmount = currentBoost + newAmount;

        bgtContract.queueBoost(validator, newAmount);
        delegationTimestamp[msg.sender] = block.timestamp;
        delegationAmount[msg.sender] = updatedAmount;
    }

    function reduceBoost(address validator, uint128 reduceAmount) external {
        uint128 currentBoost = bgtContract.boosts(msg.sender);
        require(reduceAmount <= currentBoost, "Reduction exceeds current delegation");

        uint128 updatedAmount = currentBoost - reduceAmount; 
        bgtContract.queueBoost(validator, updatedAmount);

        delegationAmount[msg.sender] = updatedAmount;
    }

    function depositBribe(uint256 iBGTAmount, uint256 starAmount) external {
        require(iBGTToken.transferFrom(msg.sender, address(this), iBGTAmount), "iBGT transfer failed");
        require(starToken.transferFrom(msg.sender, address(this), starAmount), "STAR transfer failed");

        totalIBGTBribe += iBGTAmount;
        totalSTARBribe += starAmount;

        validatorTotalBoost = bgtContract.boostees(validator);

        emit BribeDeposited(iBGTAmount, starAmount);
    }

    function claimBribe() external {
        uint256 currentEpoch = getCurrentEpoch();
        require(lastClaimedEpoch[msg.sender] < currentEpoch, "Already claimed for this epoch");
        
        require(block.timestamp >= delegationTimestamp[msg.sender] + epochDuration, "Boost must be active for full epoch");

        require(block.timestamp >= delegationTimestamp[msg.sender] + minStakeDuration, "Not staked long enough");

        require(delegationAmount[msg.sender] > 0, "Delegation reduced, no rewards");

        uint128 delegatorBoost = bgtContract.boosts(msg.sender);
        require(delegatorBoost > 0, "No boost for this delegator");

        uint256 iBGTReward = (delegatorBoost * totalIBGTBribe) / validatorTotalBoost;
        uint256 starReward = (delegatorBoost * totalSTARBribe) / validatorTotalBoost;

        iBGTToken.transfer(msg.sender, iBGTReward);
        starToken.transfer(msg.sender, starReward);

        claimedIBGT[msg.sender] += iBGTReward;
        claimedSTAR[msg.sender] += starReward;
        lastClaimedEpoch[msg.sender] = currentEpoch;

        emit BribeClaimed(msg.sender, iBGTReward, starReward);
    }

    function getCurrentEpoch() public view returns (uint256) {
        return (block.timestamp - lastEpochTime) / epochDuration;
    }

    function startNewEpoch() external {
        require(block.timestamp >= lastEpochTime + epochDuration, "Epoch not yet ended");
        totalIBGTBribe = 0;
        totalSTARBribe = 0;
        lastEpochTime = block.timestamp;
    }
}
