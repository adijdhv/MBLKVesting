 // SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
 
import "./MBLKStake.sol";
import "./LPStake.sol";

contract MBLKStakingPool is  Ownable,ReentrancyGuard {

    IERC20 public mblkToken; // The MBLK token contract
    MBLKStaked  public sMBLKToken; // The MBLK token contract
    LPStaked  public sLPToken; //The Staked LP TOKEN Contract
    IERC20 public lpToken;      //IERC20 LP Token Contract
    using SafeMath for uint256;
    address public contractAddress = (address(this)); 


    // Staking pool for MBLK
    struct MBLKStake {

        uint256 mblkAmount;
        uint256 startTimestamp;
        uint256 endTime;
        uint256 claimedReward;
        uint256 lastClaimedTimeStamp;
        uint256 StakedMBLKMinted;
        uint256 UserFees;
        uint256 CycleId;
     }

    mapping(address => MBLKStake) public userMBLKStakes;
 
     
    uint256 public totalMBLKStaked;
    uint256 public totalSMBLKminted;
    uint256 public totalSLPminted;
    uint256 public currentCycleId;
    
    struct LPStake {
        uint256 lpAmount;
        uint256 startTimestamp; 
        uint256 endTime;
        uint256 claimedReward;
        uint256 lastClaimedTimeStamp;
        uint256 StakedLPMinted;
        uint256 UserFees;
        uint256 CycleId; 
    }


  

    mapping(address => LPStake) public userLPstake;

    mapping(address => bool) public isAdmin;  

    struct StakingInfo{
        uint256 CycleId;
        uint256 blockTimeStamp;
        uint256 totalReward;
        uint256 totalLPStaked;
        uint256 totalMBLKStaked;
    }

    mapping(uint256 => StakingInfo) public stakingInfo;

    uint256 public LastDynamicRewardSet; 
    uint256 public calculateRewardMinimumTime;
    uint256 public TimeForFixedReward;
    uint256 public TimeForDynamicReward;
    uint256 public minimumThreshold;
    uint256 public LastFixedRewardSet;
    uint256 public lastTotalRewardSetTimestamp;
    uint256 public totalLPStaked;
    uint256 public fixedReward;
    uint256 public dynamicReward;
    uint256 public TOTAL_REWARDS ;  
    uint256 public minimum_Stake_duration;   
    address public feesCollectionWallet ; 
    uint256 feesPercentage = 2;
 
    //Events
    event StakeMBLK(address indexed user,uint256 mblkAmount);
    event StakeLP(address indexed user,uint256 _lpAmount );
    event CompoundRewardsAdded(address indexed user, uint256 rewardsAdded);
    event ClaimedRewardsMBLK(address indexed user,uint256 rewardsAmount );
    event ClaimedRewardsLP(address indexed user,uint256 rewardsAmount );
    event WithdrawnMBLK(address indexed user, uint256 rewardsAmount);
    event WithdrawnLP(address indexed user, uint256 rewardsAmount);
    event FixedCompoundInterestRatePercentageSet(uint256 percentage0);
    event DynamicCompoundInterestRatePercentageSet(uint256 percentage );
    event DynamicRewardDurationSet(uint256 duration);
    event VestingPeriodSet(uint256 duration);
    event TotalRewardSet(uint256 totalReward);
    event FeesPercentageSet(uint256 percentage);
    event DynamicRewardSet(uint256 dynamicReward);
    event FixedRewardSet(uint256 fixedReward);
    event MinimumStakeDurationSet(uint256 duration);
    event adminRemoved( address adminToRemove);
    event adminAdded( address adminAdded);
    event MBLKStakeUPDATED(address userAddress, uint256 amount);
    event LPStakeUPDATED(address userAddress, uint256 amount);
    event MBLKTokenAddressChanged(address _mblkTokenAddress);
    event LPTokenAddressChanged(address _lpTokenAddress);
    event SLPTokenAddressChanged( address _stakedLPTokenAddress);
    event SMBLKTokenAddressChanged(address _stakedMBLKTokenAddress);
    event UpdatedCycleId(uint256 _currentCycleId);
    event WithDrawnAll(address _owner,uint256 _BalanceMBLK, uint256 _BalanceLPToken);


 

    constructor(
        address _mblkTokenAddress,           // MBLK Token Contract address           
        address _stakedMBLKTokenAddress,     // Staked MBLK TOKEN CONTRACT ADDRESS    
        address _stakedLPTokenAddress,       // Staked LP Token Contract Address     
        address _lptokenAddress,             // Lp Token Contract Address  
        address _feesCollectionWalletAddress // Fees wallet address
    ) payable {
        mblkToken  = IERC20(_mblkTokenAddress);
        sMBLKToken = MBLKStaked(_stakedMBLKTokenAddress);
        sLPToken   = LPStaked(_stakedLPTokenAddress);
        lpToken    = IERC20(_lptokenAddress);  
        feesCollectionWallet = _feesCollectionWalletAddress;
    }




/**
 * @dev Stake a specified amount of MBLK tokens.
 * @param _mblkAmount The amount of MBLK tokens to stake.
 *
 * Requirements:
 * - The staked amount must be greater than 0.
 * - The user must not have an active MBLK stake (mblkAmount must be 0).
 * - Transfer MBLK tokens from the sender to the staking contract.
 * - Record stake-related information including start and end times, rewards, and cycle ID.
 * - Mint and distribute SMBLK tokens to the staker.
 * - Update the total MBLK staked and total SMBLK minted.
 *
 * Emits a StakeMBLK event to log the staking action.
 */


function stakeMBLK(uint256 _mblkAmount) nonReentrant  external {

        require(_mblkAmount > 0, "Amount must be greater than 0");

        require(userMBLKStakes[msg.sender].mblkAmount == 0,"Existing active stake found");  
 
        mblkToken.transferFrom(msg.sender, address(this), _mblkAmount);

        uint256 blocktimestamp = block.timestamp;   

        totalMBLKStaked += _mblkAmount;
         
        userMBLKStakes[msg.sender].mblkAmount = _mblkAmount;

        userMBLKStakes[msg.sender].startTimestamp = blocktimestamp;

        userMBLKStakes[msg.sender].endTime = blocktimestamp + minimum_Stake_duration;

        userMBLKStakes[msg.sender].lastClaimedTimeStamp = blocktimestamp;  

        sMBLKToken.mint(msg.sender,_mblkAmount);  

        totalSMBLKminted += _mblkAmount;

        uint256 TimeOfStake = blocktimestamp.sub(stakingInfo[currentCycleId].blockTimeStamp);   

        if(TimeOfStake <= minimumThreshold){

        userMBLKStakes[msg.sender].CycleId = currentCycleId + 1; 

        }else{

        userMBLKStakes[msg.sender].CycleId = currentCycleId; 

        }
        userMBLKStakes[msg.sender].StakedMBLKMinted += _mblkAmount;
  
        emit StakeMBLK(msg.sender,_mblkAmount);
}

/**
 * @dev Stake a specified amount of LP (Liquidity Provider) tokens.
 * @param _lpAmount The amount of LP tokens to stake.
 *
 * Requirements:
 * - The staked amount must be greater than 0.
 * - The sender must have a sufficient balance of LP tokens to stake.
 * - The user must not have an active LP stake (lpAmount must be 0).
 * - Transfer LP tokens from the sender to the staking contract.
 * - Record stake-related information including start and end times, rewards, and cycle ID.
 * - Mint and distribute SLP tokens to the staker.
 * - Update the total LP tokens staked and total SLP tokens minted.
 *
 * Emits a StakeLP event to log the staking action.
 */
function StakeLPtoken(uint256 _lpAmount) nonReentrant external {

        require(_lpAmount > 0 , "Amount must be greater than 0 " );
        
        require( lpToken.balanceOf(msg.sender) >= _lpAmount, "Not enough _lpToken");

        require(userLPstake[msg.sender].lpAmount == 0,"Existing LP Stake Found");

        require(lpToken.transferFrom(msg.sender,address(this), _lpAmount), "Transfer to staking failed");  
     
        totalLPStaked += _lpAmount;
 
        uint256 blocktimestamp = block.timestamp;
        
        userLPstake[msg.sender].lpAmount += _lpAmount;
        
        userLPstake[msg.sender].startTimestamp = blocktimestamp;
        
        userLPstake[msg.sender].endTime = blocktimestamp + minimum_Stake_duration;
  
        userLPstake[msg.sender].lastClaimedTimeStamp = blocktimestamp;   
 
        sLPToken.mint(msg.sender,_lpAmount);          //Staked LP Token MInted to User Address

        totalSLPminted +=  _lpAmount;

        userLPstake[msg.sender].StakedLPMinted += _lpAmount;

        uint256 TimeOfStake = blocktimestamp.sub(stakingInfo[currentCycleId].blockTimeStamp);

        if(TimeOfStake <= minimumThreshold){

            userMBLKStakes[msg.sender].CycleId = currentCycleId + 1; 

        }else{

            userMBLKStakes[msg.sender].CycleId = currentCycleId;  
        }

        emit StakeLP(msg.sender,_lpAmount); 
}


/**
 * @dev Update the current staking cycle information.
 *
 * This function increments the currentCycleId, records the block timestamp, and updates the staking information for the new cycle, including total rewards, LP tokens staked, and MBLK tokens staked.
 *
 * Requirements:
 * - Only the admin can call this function.
 *
 * Emits an UpdatedCycleId event with the new cycle's identifier.
 */

function UpdateCycleId() public onlyAdmin {

        currentCycleId++;

        uint256 blockTimeStamp = block.timestamp;

        stakingInfo[currentCycleId].CycleId =  currentCycleId;

        stakingInfo[currentCycleId].blockTimeStamp = blockTimeStamp;

        stakingInfo[currentCycleId].totalReward = TOTAL_REWARDS;

        stakingInfo[currentCycleId].totalLPStaked = totalLPStaked;

        stakingInfo[currentCycleId].totalMBLKStaked = totalMBLKStaked;

        emit UpdatedCycleId(currentCycleId);

}
  

/**
 * @dev Calculate the rewards for a user based on their staking Parcentage.
 * @param _userAddress The address of the user.
 * @param _isMBLK A boolean indicating whether the user has MBLK staked (true) or LP staked (false).
 * @return The calculated reward amount for the user 
 *
 * Requirements:
 * - The user must have a staking amount greater than 0.
 * - The owner/admin must have set the minimum time for calculating rewards (calculateRewardMinimumTime).
 *
 * The function calculates rewards by iterating through cycles, determining the user's stake percentage, and applying it to the total rewards.
 * The calculated reward is based on the User Stake Percentage each cycle.
 */
 
function calculateReward(address _userAddress, bool _isMBLK) public view returns(uint256){ 
     
        uint256 totalRewardsCalculated;
        uint256 _iether = 10**18;

        if(_isMBLK){
 
            MBLKStake storage userStake =  userMBLKStakes[_userAddress] ;

            require(userStake.mblkAmount > 0,"No Stakes Found"); 

            require(calculateRewardMinimumTime > 0, "Owner Haven't Set calculate Reward minimum Time");
      
            uint256 elapsedTimeFromLastClaimed = block.timestamp - userStake.lastClaimedTimeStamp ;

            if(elapsedTimeFromLastClaimed >= calculateRewardMinimumTime){
         
                for(uint256 i = userStake.CycleId + 1; i <= currentCycleId; i++){

                    require(stakingInfo[i].totalMBLKStaked > 0,"No Mblk has Been staked before last cycle");

                    uint256 StructtotalReward = stakingInfo[i].totalReward;

                    uint256 StructtotalMBLKstaked = stakingInfo[i].totalMBLKStaked;

                    uint256 mblkStakePercentage = (userStake.mblkAmount.mul(100)).div(StructtotalMBLKstaked);

                    uint256 totalRewards = (mblkStakePercentage.mul(StructtotalReward).mul(_iether.mul(30))).div(_iether.mul(10000)); 

                    totalRewardsCalculated = totalRewards;
                }

                return totalRewardsCalculated;

            } else {
                return 0;
            }
  
        } else {
 
            LPStake storage userStake = userLPstake[_userAddress];
 
            require(calculateRewardMinimumTime > 0, "Owner Haven't Set calculate Reward minimum Time");
         
            uint256 elapsedTimeFromLastClaimed = block.timestamp - userStake.lastClaimedTimeStamp ;

            if(elapsedTimeFromLastClaimed >= calculateRewardMinimumTime){

                for(uint256 i = userStake.CycleId + 1; i <= currentCycleId; i++){

                    require(stakingInfo[i].totalLPStaked > 0,"No LP Token has Been staked before last cycle");

                    uint256 StructtotalReward = stakingInfo[i].totalReward;

                    uint256 StructtototalLPStaked = stakingInfo[i].totalLPStaked;

                    uint256 lpStakePercentage = (userStake.lpAmount.mul(100)).div(StructtototalLPStaked);

                    uint256 totalRewardsinMBLK = (lpStakePercentage.mul(StructtotalReward).mul(_iether.mul(70))).div(_iether.mul(10000)); // 70 percent reward of TOTAL_REWARD

                    totalRewardsCalculated += totalRewardsinMBLK;
                }
            return totalRewardsCalculated;

            }else{
                return 0;
            }
        }
}


/**
 * @dev Claim MBLK rewards for a user.
 *
 * This function allows a user to claim their MBLK rewards based on their staking Parcentage. The rewards are calculated using the 'calculateReward' function.
 * A fee is deducted from the total rewards, and the remaining amount is transferred to the user. The fee amount is also transferred to a specified feesCollectionWallet.
 *
 * Requirements:
 * - The user must have an active MBLK stake.
 * - The calculated reward must be greater than 0.
 *
 * Emits a ClaimedRewardsMBLK event to log the claimed rewards.
 */
function claimRewardsMBLK()  nonReentrant public {

        MBLKStake storage userStake = userMBLKStakes[msg.sender];
 
        require(userStake.mblkAmount > 0, "No single MBLK stake found");
 
        uint256 _totalReward = calculateReward(msg.sender,true);

        require(_totalReward > 0, "No rewards to claim"); 
  
        uint256 feeAmount = _totalReward.mul(feesPercentage).div(10000);

        uint256 AmountToSend = _totalReward.sub(feeAmount);

        userStake.lastClaimedTimeStamp = block.timestamp;

        userStake.claimedReward += _totalReward;

        userStake.CycleId = currentCycleId;

        mblkToken.transfer(msg.sender, AmountToSend); 

        mblkToken.transfer(feesCollectionWallet, feeAmount);
        
        emit ClaimedRewardsMBLK(msg.sender, _totalReward);
       
}

/**
 * @dev Claim LP token rewards for a user.
 *
 * This function allows a user to claim their LP token rewards based on their staking Parcentage. The rewards are calculated using the 'calculateReward' function.
 * A fee is deducted from the total rewards, and the remaining amount is transferred to the user. The fee amount is also transferred to a specified feesCollectionWallet.
 *
 * Requirements:
 * - The user must have an active LP token stake.
 * - The calculated reward must be greater than 0.
 *
 * Emits a ClaimedRewardsLP event to log the claimed rewards.
 */

function ClaimRewardsLP() nonReentrant public {

    LPStake storage userStake = userLPstake[msg.sender];
     
    require(userStake.lpAmount > 0  , "No LP TOKEN stake found");

    uint256 lprewards  =  calculateReward(msg.sender,false);

    uint256 feeAmount = (lprewards.mul(feesPercentage)).div(10000);

    uint256 AmountToSend = lprewards.sub(feeAmount);

    userStake.claimedReward += lprewards;

    userStake.CycleId = currentCycleId;

    userStake.lastClaimedTimeStamp = block.timestamp;
     
    mblkToken.transfer(msg.sender, AmountToSend);
    
    mblkToken.transfer(feesCollectionWallet, feeAmount);

    emit ClaimedRewardsLP(msg.sender, lprewards);
}

 
/**
 * @dev Withdraw a specified amount of MBLK tokens from the user's stake.
 * @param _amountTowithdraw The amount of MBLK tokens to withdraw.
 *
 * Requirements:
 * - The user must have an active MBLK stake.
 * - The calculated rewards must be claimed first (calculatedRewards must be 0).
 * - The withdrawal can only occur after the minimum stake duration has passed.
 * - The contract must have a sufficient balance of MBLK tokens.
 *
 * Effects:
 * - Transfers the specified amount of MBLK tokens to the user.
 * - Burns an equivalent amount of SMBLK tokens from the user's balance.
 * - Updates the user's stake and total MBLK and SMBLK minted values.
 *
 * Emits a WithdrawnMBLK event to log the MBLK withdrawal.
 */

function withdrawMBLK(uint256 _amountTowithdraw) nonReentrant external {
    
    uint256 calculatedRewards = calculateReward(msg.sender,true);

    require(calculatedRewards == 0 , "Please claim the rewards first");

    MBLKStake storage userStake = userMBLKStakes[msg.sender];
    
    require(userStake.mblkAmount > 0, "No active stake found");
 
    require(userStake.endTime < block.timestamp , "Can not withdraw before Minimum Stake Duration ");
 
    require(mblkToken.balanceOf(address(this)) >= _amountTowithdraw, "Contract balance is not enough");
 
    require(mblkToken.transfer(msg.sender, _amountTowithdraw), "Transfer failed");      
 
    sMBLKToken.burnFrom(msg.sender, _amountTowithdraw) ;

    userStake.mblkAmount -= _amountTowithdraw;

    userStake.StakedMBLKMinted -= _amountTowithdraw;
  
    totalSMBLKminted -= _amountTowithdraw;

    totalMBLKStaked -= _amountTowithdraw;

    emit WithdrawnMBLK(msg.sender,   _amountTowithdraw);
    
}


/**
 * @dev Withdraw a specified amount of LP (Liquidity Provider) tokens from the user's stake.
 * @param _amountToWithdraw The amount of LP tokens to withdraw.
 *
 * Requirements:
 * - The user must have an active LP token stake.
 * - The calculated rewards must be claimed first (calculatedRewards must be 0).
 * - The withdrawal can only occur after the minimum stake duration has passed.
 * - The contract must have a sufficient balance of LP tokens and SMBLK tokens.
 *
 * Effects:
 * - Transfers the specified amount of LP tokens to the user.
 * - Burns an equivalent amount of SMBLK tokens from the user's balance.
 * - Updates the user's stake, total LP staked, and total SLP minted values.
 *
 * Emits a WithdrawnLP event to log the LP token withdrawal.
 */

function withdrawLP(uint256 _amountToWithdraw) nonReentrant external {
 
        uint256 blocktimeStamp = block.timestamp;

        LPStake storage userStake = userLPstake[msg.sender];

         uint256 calculatedRewards = calculateReward(msg.sender,false);

        require(calculatedRewards == 0 , "Please claim the rewards first");

        require(userStake.lpAmount > 0, "No active stake found");

        require(userStake.endTime < blocktimeStamp , "Can not withdraw before Minimum Stake Duration ");
        
        require(userStake.lpAmount >= _amountToWithdraw, "Contract balance is not enough");

        require(sLPToken.balanceOf(msg.sender) >= _amountToWithdraw, "user smblk Balance is not enough");

        require(lpToken.balanceOf(address(this)) >= _amountToWithdraw, "Contract Balance is not enough");

        sLPToken.burnFrom(msg.sender,_amountToWithdraw);

        require(lpToken.transfer(msg.sender, _amountToWithdraw), "LP token Trasnfer Failed");

        userStake.lpAmount -= _amountToWithdraw;

        totalLPStaked -= _amountToWithdraw;

        totalSLPminted -= _amountToWithdraw;
        
        userStake.StakedLPMinted -= _amountToWithdraw;

        emit WithdrawnLP(msg.sender, _amountToWithdraw);
}
 

/**
 * @dev Update a user's stake with additional tokens.
 * @param _amount The amount of tokens to add to the user's stake.
 * @param _isMBLK A boolean indicating whether the stake is for MBLK (true) or LP (false).
 *
 * Requirements:
 * - The added amount must be greater than 0.
 * - The calculated rewards must be claimed first (calculatedRewards must be 0).
 * - If the stake is for MBLK, the user must have an existing active MBLK stake; if the stake is for LP, the user must have an existing active LP stake.
 * - Transfer tokens from the sender to the staking contract.
 * - Update stake-related information, including start and end times, rewards, and cycle ID.
 *
 * Emits an MBLKStakeUPDATED event if updating an MBLK stake, or an LPStakeUPDATED event if updating an LP stake, to log the stake update.
 */

function updateStake( uint256 _amount , bool _isMBLK) public {

    require(_amount > 0, "Amount must be greater than 0");

    if(_isMBLK){
        
        uint256 calculatedRewards = calculateReward(msg.sender,true);

        require(calculatedRewards == 0 , "Please claim the rewards first");

        MBLKStake storage userStake = userMBLKStakes[msg.sender];

        require(userMBLKStakes[msg.sender].mblkAmount > 0,"Existing active stake not found");

        mblkToken.transferFrom(msg.sender, address(this), _amount);

        totalMBLKStaked += _amount;

        userStake.mblkAmount += _amount;

        uint256 blockTimeStamp = block.timestamp; 

        userStake.startTimestamp = blockTimeStamp;

        userStake.endTime = blockTimeStamp.add(minimum_Stake_duration);

        sMBLKToken.mint(msg.sender,_amount);   

        totalSMBLKminted += _amount;

        userMBLKStakes[msg.sender].StakedMBLKMinted += _amount;

        uint256 TimeOfStake = blockTimeStamp.sub(stakingInfo[currentCycleId].blockTimeStamp);

        if(TimeOfStake <= minimumThreshold){

        userMBLKStakes[msg.sender].CycleId = currentCycleId + 1; 

        }else{

        userMBLKStakes[msg.sender].CycleId = currentCycleId; 

        }

        emit MBLKStakeUPDATED(msg.sender,_amount);
 
    }else{
        LPStake storage userStake = userLPstake[msg.sender];

        uint256 calculatedRewards = calculateReward(msg.sender,false);

        require(calculatedRewards == 0 , "Please claim the rewards first");

        require(userStake.lpAmount > 0,"Existing active stake not found");

        lpToken.transferFrom(msg.sender, address(this), _amount);

        totalLPStaked += _amount;

        userStake.lpAmount += _amount;

        uint256 blockTimeStamp = block.timestamp; 

        userStake.startTimestamp = blockTimeStamp;

        userStake.endTime = blockTimeStamp.add(minimum_Stake_duration);

        sLPToken.mint(msg.sender,_amount);  
 
        totalSLPminted += _amount;

        userLPstake[msg.sender].StakedLPMinted += _amount;

        uint256 TimeOfStake = blockTimeStamp.sub(stakingInfo[currentCycleId].blockTimeStamp);

        if(TimeOfStake <= minimumThreshold){

        userMBLKStakes[msg.sender].CycleId = currentCycleId + 1; 

        }else{

        userMBLKStakes[msg.sender].CycleId = currentCycleId; 

        }

        emit LPStakeUPDATED(msg.sender,_amount);
    }
}

 
/**
 * @dev Set the minimum stake duration in minutes.
 * @param duration_in_minutes The minimum stake duration in minutes to be set.
 *
 * Requirements:
 * - The provided duration must be greater than 0.
 *
 * Effects:
 * - Converts the input duration in minutes to seconds and updates the 'minimum_Stake_duration' variable.
 *
 * Emits a MinimumStakeDurationSet event to log the update of the minimum stake duration.
 */
function setMinimumStakeDuration(uint256 duration_in_minutes)external onlyOwner {

        require(duration_in_minutes > 0  , "Given Value is 0" ); 

        minimum_Stake_duration = duration_in_minutes.mul(60);

        emit MinimumStakeDurationSet(duration_in_minutes);
}
 
/**
 * @dev Set a fixed reward value for staking.
 * @param _fixedReward The fixed reward value to be set.
 *
 * Requirements:
 * - Only the admin can call this function.
 * - The time since the last fixed reward update must be greater than or equal to 'TimeForFixedReward'.
 *
 * Effects:
 * - Updates the 'fixedReward' value.
 * - Calls 'setTOTAL_REWARDS' to set total rewards based on the fixed reward.
 *
 * Emits a FixedRewardSet event to log the update of the fixed reward value.
 */
function setFixedReward(uint256 _fixedReward) external  onlyAdmin{

    uint256 blocktimeStamp = block.timestamp ;

    uint256 TimeSpent = blocktimeStamp.sub(LastFixedRewardSet); 
     
    if (TimeSpent >= TimeForFixedReward){
         
    LastFixedRewardSet = blocktimeStamp;
 
    fixedReward = _fixedReward;

    setTOTAL_REWARDS();

    }else{

    require(TimeSpent >= TimeForFixedReward,"Can not set before Minimum Time");
    }

    emit FixedRewardSet(_fixedReward);
}


/**
 * @dev Set the dynamic reward value, but only if enough time has passed since the last update.
 * @param _dynamicReward The new dynamic reward value to set.
 *
 * Requirements:
 * - The function can only be called by the admin.
 * - The time elapsed since the last dynamic reward update must be greater than or equal to `TimeForDynamicReward`.
 * - If the time requirement is met, the dynamic reward value is updated, and `setTOTAL_REWARDS` is called.
 *
 * Emits a DynamicRewardSet event with the new dynamic reward value.
 */

function setDynamicReward(uint256 _dynamicReward) external onlyAdmin {

    uint256 blocktimeStamp = block.timestamp ;

    uint256 TimeSpent = blocktimeStamp.sub(LastDynamicRewardSet);

    
     if (TimeSpent >= TimeForDynamicReward) {
        dynamicReward = 0;
        LastDynamicRewardSet = blocktimeStamp;
        dynamicReward = _dynamicReward; 
        setTOTAL_REWARDS();

     }else{
        require(TimeSpent >= TimeForDynamicReward,"Can not set Before minimum time");
     }

    emit DynamicRewardSet(_dynamicReward);
}



/**
 * @dev Set the total rewards for staking.
 *
 * Effects:
 * - Calculates the 'TOTAL_REWARDS' by adding the 'fixedReward' and 'dynamicReward'.
 * - Records the timestamp when the total rewards were last set.
 *
 * Emits a TotalRewardSet event to log the update of the total rewards.
 */
function setTOTAL_REWARDS() internal {

    TOTAL_REWARDS = fixedReward.add(dynamicReward);
 
    lastTotalRewardSetTimestamp = block.timestamp;

    emit TotalRewardSet(TOTAL_REWARDS);
}

/**
 * @dev Set the fees percentage for reward distribution.
 * @param percentage The fees percentage to be set (0-10000, where 10000 represents 100%).
 *
 * Requirements:
 * - Only the admin can call this function.
 * - The provided percentage must be within the valid range (0-10000).
 *
 * Effects:
 * - Updates the 'feesPercentage' for fee calculations.
 *
 * Emits a FeesPercentageSet event to log the update of the fees percentage.
 */
function setFeesPercentage(uint256 percentage) external onlyAdmin {

    require( percentage > 0 && percentage <= 10000, "Percentage out of range (0-10000)" );

    feesPercentage = percentage;

    emit FeesPercentageSet(percentage);
} 

/**
 * @dev Add a new address as an admin.
 * @param _newAdmin The address to be added as a new admin.
 *
 * Requirements:
 * - Only the contract owner can call this function.
 *
 * Effects:
 * - Grants administrative privileges to the specified address by setting 'isAdmin[_newAdmin]' to true.
 *
 * Emits an adminAdded event to log the addition of a new admin.
 */
function addAdmin(address _newAdmin) public onlyOwner {

    isAdmin[_newAdmin] = true;

    emit adminAdded( _newAdmin);
}

/**
 * @dev Remove an address from the list of admins.
 * @param _adminAddress The address to be removed from the list of admins.
 *
 * Requirements:
 * - Only the contract owner can call this function.
 *
 * Effects:
 * - Revokes administrative privileges from the specified address by setting 'isAdmin[_adminAddress]' to false.
 *
 * Emits an adminRemoved event to log the removal of an admin.
 */
function removeAdmin(address _adminAddress) public onlyOwner {

    isAdmin[_adminAddress] = false;
        
    emit adminRemoved( _adminAddress);
}


/**
 * @dev Change the address of the MBLK token contract.
 * @param _mblkTokenAddress The new address of the MBLK token contract.
 *
 * Requirements:
 * - Only the contract owner can call this function.
 *
 * Effects:
 * - Updates the 'mblkToken' variable with the new MBLK token contract address.
 *
 * Emits an MBLKTokenAddressChanged event to log the change of the MBLK token contract address.
 */
function changeMBLKTokenAddress(address _mblkTokenAddress) public onlyOwner {

    mblkToken = IERC20(_mblkTokenAddress);

    emit MBLKTokenAddressChanged( _mblkTokenAddress);
}

/**
 * @dev Change the address of the LP (Liquidity Provider) token contract.
 * @param _lpTokenAddress The new address of the LP token contract.
 *
 * Requirements:
 * - Only the contract owner can call this function.
 *
 * Effects:
 * - Updates the 'lpToken' variable with the new LP token contract address.
 *
 * Emits an LPTokenAddressChanged event to log the change of the LP token contract address.
 */
function changeLPTokenAddress( address _lpTokenAddress) public onlyOwner {

    lpToken =  IERC20(_lpTokenAddress);

    emit LPTokenAddressChanged( _lpTokenAddress)  ;
}

/**
 * @dev Change the address of the staked LP (Staked Liquidity Provider) token contract.
 * @param _stakedLPTokenAddress The new address of the staked LP token contract.
 *
 * Requirements:
 * - Only the contract owner can call this function.
 *
 * Effects:
 * - Updates the 'sLPToken' variable with the new staked LP token contract address.
 *
 * Emits an SLPTokenAddressChanged event to log the change of the staked LP token contract address.
 */
function changeSLPTokenAddress( address _stakedLPTokenAddress) public onlyOwner {

        sLPToken = LPStaked(_stakedLPTokenAddress);

        emit SLPTokenAddressChanged(  _stakedLPTokenAddress);    
}

/**
 * @dev Change the address of the staked MBLK  token contract.
 * @param _stakedMBLKTokenAddress The new address of the staked MBLK token contract.
 *
 * Requirements:
 * - Only the contract owner can call this function.
 *
 * Effects:
 * - Updates the 'sMBLKToken' variable with the new staked MBLK token contract address.
 *
 * Emits an SMBLKTokenAddressChanged event to log the change of the staked MBLK token contract address.
 */

function changeSMBLKTokenAddress( address _stakedMBLKTokenAddress) public onlyOwner {

    sMBLKToken = MBLKStaked(_stakedMBLKTokenAddress);

    emit SMBLKTokenAddressChanged( _stakedMBLKTokenAddress);
}

/**
 * @dev Set the address where collected fees will be sent.
 * @param _walletAddress The address where collected fees will be transferred to.
 *
 * Requirements:
 * - Only the contract owner can call this function.
 *
 * Effects:
 * - Updates the 'feesCollectionWallet' with the provided wallet address.
 */
function setFeeWalletAddress( address _walletAddress) public onlyOwner {

        feesCollectionWallet = _walletAddress;
}

/**
 * @dev Set the minimum time duration for calculating rewards.
 * @param duration_in_minutes The minimum time duration in minutes for calculating rewards.
 *
 * Requirements:
 * - Only the contract owner can call this function.
 *
 * Effects:
 * - Converts the input duration in minutes to seconds and updates 'calculateRewardMinimumTime'.
 */
function setMinimumCalculateRewardTime( uint256 duration_in_minutes ) public onlyOwner {
            
        calculateRewardMinimumTime = duration_in_minutes.mul(60);
}

/**
 * @dev Set the time interval for dynamic reward updates.
 * @param duration_in_minutes The time interval in minutes for updating dynamic rewards.
 *
 * Requirements:
 * - Only the contract owner can call this function.
 *
 * Effects:
 * - Converts the input duration in minutes to seconds and updates 'TimeForDynamicReward'.
 */
function setDynamicRewardTime( uint256 duration_in_minutes ) public onlyOwner {

    TimeForDynamicReward = duration_in_minutes.mul(60);
}

/**
 * @dev Set the time interval for fixed reward updates.
 * @param duration_in_minutes The time interval in minutes for updating fixed rewards.
 *
 * Requirements:
 * - Only the contract owner can call this function.
 *
 * Effects:
 * - Converts the input duration in minutes to seconds and updates 'TimeForFixedReward'.
 */
function setFixedRewardTime( uint256 duration_in_minutes ) public onlyOwner {

    TimeForFixedReward = duration_in_minutes.mul(60); 
}

/**
 * @dev Set the minimum time threshold for determining the stake cycle.
 * @param duration_in_minutes The minimum time threshold in minutes to consider a stake within the same cycle.
 *
 * Requirements:
 * - Only the contract owner can call this function.
 *
 * Effects:
 * - Converts the input duration in minutes to seconds and updates 'minimumThreshold'.
 */
function setMinimumThreshold(uint256 duration_in_minutes) public onlyOwner{

    minimumThreshold = duration_in_minutes.mul(60); 
}


/**
 * @dev Withdraw MBLK and LP tokens from the contract by the owner.
 *
 * Requirements:
 * - Only the contract owner can call this function.
 *
 * Effects:
 * - Transfers the entire balance of MBLK and LP tokens from the contract to the owner's address.
 *
 * Emits a WithDrawnAll event to log the withdrawal of MBLK and LP tokens by the owner.
 */

function withdrawOnlyOwner() public onlyOwner {

    uint256 BalanceMBLK = mblkToken.balanceOf(contractAddress);

    uint256 BalanceLPToken = lpToken.balanceOf(contractAddress);

    mblkToken.transfer(msg.sender,BalanceMBLK);

    lpToken.transfer(msg.sender, BalanceLPToken);

    emit WithDrawnAll(msg.sender,BalanceMBLK,BalanceLPToken);
}

/**
 * @dev Get the total amount of SMBLK (Staked MBLK) minted.
 * @return The total number of SMBLK tokens that have been minted as rewards.
 */
function totalSMBLK()public view returns(uint256 ){
    return totalSMBLKminted;
}



/**
 * @dev Get the total amount of SLP (Staked LP) tokens minted.
 * @return The total number of SLP tokens that have been minted as rewards.
 */

function totalSLP()public view returns(uint256 ){
    return totalSLPminted;
}
 


/**
 * @dev Get information about a user's MBLK stake.
 * @param _userAddress The address of the user.
 * @return (
 *   1. The amount of MBLK staked by the user,
 *   2. The start timestamp of the stake,
 *   3. The end timestamp of the stake,
 *   4. The claimed reward amount,
 *   5. The last claimed timestamp,
 *   6. The amount of Staked MBLK minted,
 *   7. The user's fees associated with the stake.
 * )
 */
function userMBLKStakeInformation( address _userAddress) public view returns(uint256 , uint256 ,uint256 ,uint256  , uint256  ,uint256 ,uint256){
     
     MBLKStake storage userStake = userMBLKStakes[_userAddress];

           return(
            userStake.mblkAmount,
            userStake.startTimestamp,
            userStake.endTime,
            userStake.claimedReward, 
            userStake.lastClaimedTimeStamp,
            userStake.StakedMBLKMinted,
            userStake.UserFees
        );
}

/**
 * @dev Get information about a user's LP stake.
 * @param _userAddress The address of the user.
 * @return (
 *   1. The amount of LP tokens staked by the user,
 *   2. The start timestamp of the stake,
 *   3. The end timestamp of the stake,
 *   4. The claimed reward amount,
 *   5. The last claimed timestamp,
 *   6. The amount of Staked LP tokens minted,
 *   7. The user's fees associated with the stake.
 * )
 */
function userLPStakeInformation( address _userAddress) public view returns(uint256 , uint256 ,uint256 ,uint256   ,uint256  ,uint256,uint256 ){
    
    LPStake storage userStake = userLPstake[_userAddress]; 
         return(
            userStake.lpAmount,
            userStake.startTimestamp,
            userStake.endTime,
            userStake.claimedReward, 
            userStake.lastClaimedTimeStamp, 
            userStake.StakedLPMinted,
            userStake.UserFees
        ); 
}

/**
 * @dev Get the total amount of rewards available for distribution.
 * @return The total number of rewards 
 */

function getTotalRewards()public view returns( uint256 ){
    return TOTAL_REWARDS;
} 



/**
 * @dev Get staking information for a specific cycle.
 * @param _cycleId The identifier of the staking cycle to retrieve information for.
 * @return (
 *   1. The cycle ID,
 *   2. The block timestamp when the cycle was updated,
 *   3. The total amount of MBLK tokens staked in the cycle,
 *   4. The total reward associated with the cycle,
 *   5. The total amount of LP tokens staked in the cycle.
 * )
 *
 * Requirements:
 * - The provided _cycleId must be within a valid range (not exceeding currentCycleId).
 */
function getStakingInfo(uint256 _cycleId) public view returns(uint256,uint256,uint256,uint256,uint256){

    require(_cycleId <= currentCycleId,"Cycle Id is out of Range");

    return(
    stakingInfo[_cycleId].CycleId,
    stakingInfo[_cycleId].blockTimeStamp,
    stakingInfo[_cycleId].totalMBLKStaked,
    stakingInfo[_cycleId].totalReward, 
    stakingInfo[_cycleId].totalLPStaked
    );
    
}


/*
    * @dev Modifer which allows ADMIN LIST TO ACCESS THE FUNCTION
*/
   
modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only admins can call this function");
        _;
}

}
