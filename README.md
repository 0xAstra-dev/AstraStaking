### 0xAstra Berachain Contract 

#### StarLPStaking Contract:
This contract allows users to stake STAR LP tokens to earn BGT rewards. Users can claim their rewards through the contract.

#### veSTAR (Vote-Escrowed STAR):
The veSTAR contract enables users to lock STAR tokens for governance participation. By locking STAR for varying periods, users receive veSTAR, which provides voting power and boosts their rewards from liquidity staking. The longer the lock duration, the more veSTAR a user receives, aligning incentives with the protocol’s long-term growth. veSTAR holders can vote on important protocol decisions and receive higher rewards in the StarLPStaking contract based on their veSTAR holdings.

#### Governance Contract:
The Governance Contract allows veSTAR holders to participate in the decision-making process of the Astra ecosystem. By holding veSTAR, users gain the right to vote on key protocol changes, including liquidity management, reward distributions, and upgrades to the system. Votes are weighted based on the amount of veSTAR a user holds, meaning long-term stakeholders have a greater influence over governance decisions. The contract ensures that proposals are transparent, and governance decisions are executed securely through a timelock contract that gives time for governance reviews.

#### Bribe Contract (for Delegators):
The Bribe Contract is designed to incentivize delegators who boost their BGT tokens with validators. 

#### veSTARRewards (iBGT Distribution):
This contract handles liquidity provisioning using cross-chain fees to add liquidity to Berachain pools. The generated LP tokens allow the contract to earn BGT rewards, which are automatically distributed as iBGT between staking rewards and the game pool. Seventy percent of the iBGT rewards are allocated to users who stake ASTR tokens, while 30% is reserved for the game pool, supporting Astra's in-game economy and resource management. Users can claim their iBGT rewards through the contract, which can be used in various DeFi applications or within Astra’s game economy.

#### Game Economy Integration:
The game pool receives a portion of the iBGT rewards, which can be utilized in Astra's in-game economy, promoting further engagement with the gaming aspects of the ecosystem. This helps balance in-game resources while providing liquidity to the DeFi side of the ecosystem, ensuring Astra’s in-game economy and the broader liquidity system remain healthy and balanced.

#### Resource Synthesis
Used to synthesize gaming resources